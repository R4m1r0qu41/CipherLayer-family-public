#!/usr/bin/env bash
# CipherLayer family system test — all three products working as one system.
#
#   scam-guard (FPL findings) ──► wallet (risk → policy → sign, v0.3 socket)
#                                    ▲
#   browser (broker + harness) ─────┘   (pinned wire contracts only)
#
# Runs: per-repo CI gates → Anvil → wallet `connect serve` with the real FPL
# detector wired in → browser provider-harness (contract checks incl. FPL
# origin evidence and the v0.4 signing/rpc paths) → wallet integration suites
# incl. the FPL weave test.
# Everything is dev-chain (31337) with Anvil dev keys; nothing here touches
# real funds by construction.

set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
WALLET="$ROOT/wallet"
BROWSER="$ROOT/browser"
SG="$ROOT/scam-guard"
FPL_BIN="$SG/target/debug/scam-guard"
PASS=0; FAIL=0
step() { # step <name> <command...>
  local name="$1"; shift
  if "$@" > /tmp/cl-system-step.log 2>&1; then
    echo "[PASS] $name"; PASS=$((PASS+1))
  else
    echo "[FAIL] $name — tail of log:"; tail -15 /tmp/cl-system-step.log; FAIL=$((FAIL+1))
  fi
}

echo "== CipherLayer system test =="

# 1. Product CI gates (fmt + clippy -D warnings + unit tests).
step "scam-guard ci gate"  make -C "$SG" ci
step "wallet ci gate"      make -C "$WALLET" ci
step "browser build+lint"  bash -c "cd '$BROWSER' && cargo clippy --workspace --all-targets -- -D warnings && cargo test --workspace"

# 2. Chain + wallet transport (with the real FPL detector in the risk step).
# The FPL steps exec the scam-guard *binary*; `make ci`'s cargo test never
# links it, so a cold runner has no target/debug/scam-guard without this.
( cd "$SG" && cargo build -q )
[ -x "$FPL_BIN" ] || { echo "[FAIL] scam-guard binary missing at $FPL_BIN"; exit 1; }
make -C "$WALLET" anvil-up  > /dev/null 2>&1
rm -f "$WALLET/data/browser-connect.sock"
# Prebuild the CLI binary so the serve process starts immediately — on a cold
# CI runner the link step alone can outlast any reasonable socket wait.
( cd "$WALLET" && cargo build -q -p cipherlayer-cli )
( cd "$WALLET" && CIPHERLAYER_FPL_BIN="$FPL_BIN" \
    cargo run -q -p cipherlayer-cli -- connect serve --yes > /tmp/cl-system-serve.log 2>&1 & )
for _ in $(seq 1 240); do [ -S "$WALLET/data/browser-connect.sock" ] && break; sleep 0.5; done
[ -S "$WALLET/data/browser-connect.sock" ] || {
  echo "[FAIL] wallet transport never came up — serve log tail:";
  tail -30 /tmp/cl-system-serve.log;
  exit 1;
}

# 3. Browser → wallet over the live socket, with FPL origin evidence.
# Protocol v0.3 (ADR-013): the harness must attest as the launched host, so it
# needs the wallet's per-serve host token (<socket-dir>/connect-host-token).
HOST_TOKEN_FILE="$WALLET/data/connect-host-token"
for _ in $(seq 1 20); do [ -f "$HOST_TOKEN_FILE" ] && break; sleep 0.5; done
step "browser harness: contract paths incl. FPL origin evidence + v0.4 signing/rpc" \
  bash -c "cd '$BROWSER' && CIPHERLAYER_FPL_BIN='$FPL_BIN' CIPHERLAYER_CONNECT_SOCKET='$WALLET/data/browser-connect.sock' CIPHERLAYER_CONNECT_HOST_TOKEN=\"\$(cat '$HOST_TOKEN_FILE')\" cargo run -q -p provider-harness"

# 4. Wallet integration suites, including the FPL weave test.
step "wallet integration + weave (scam-guard findings in the risk step)" \
  bash -c "cd '$WALLET' && CIPHERLAYER_INTEGRATION=1 CIPHERLAYER_FPL_BIN='$FPL_BIN' cargo test --workspace --test '*' -- --test-threads=1"

# 5. Direct product weave: wallet decoder piped into Scam Guard.
step "decode → scam-guard pipe flags unlimited approval" \
  bash -c "cd '$WALLET' && cargo run -q -p cipherlayer-cli -- decode --to 0x00000000000000000000000000000000000000cc --data 0x095ea7b30000000000000000000000000707070707070707070707070707070707070707ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff | '$FPL_BIN' --json check intent - | grep -q 'SG-ALLOW-001'"

# Teardown.
pkill -f "cipherlayer-cli connect" 2>/dev/null
make -C "$WALLET" anvil-down > /dev/null 2>&1

echo "== system test: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
