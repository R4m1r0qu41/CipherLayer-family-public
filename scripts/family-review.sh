#!/usr/bin/env bash
# CipherLayer family review loop — Tier 0 (CIPHERLAYER-FAMILY-GUIDE.md §7).
# Deterministic, offline, no model. Runs every repo's fast invariant checks
# plus the cross-repo contract-pin drift check; with --full it also runs the
# heavy per-repo `make ci` gates + the cross-product weave (system-test.sh).
#
# Usage:
#   ./scripts/family-review.sh          # fast: invariants + pin drift (~5s)
#   ./scripts/family-review.sh --full    # + make ci x3 + Anvil weave (~5min)
#
# Writes a machine-readable report to .family-review/latest.json for the
# Tier-1 triage script (family-review-triage.sh) to consume. Exit 0 = all
# clear, exit 1 = something failed and needs a look.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

FULL=0
[ "${1:-}" = "--full" ] && FULL=1

mkdir -p .family-review
REPORT=".family-review/latest.json"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

overall_fail=0
declare_result() { # name status(pass/fail) detail
  echo "{\"check\":\"$1\",\"status\":\"$2\",\"detail\":$(jq -Rs . <<<"$3")}"
}

results=()

run_check() {
  local name="$1"; shift
  echo ""
  echo "############################################"
  echo "# $name"
  echo "############################################"
  local out status
  out="$("$@" 2>&1)"
  status=$?
  echo "$out"
  if [ "$status" = "0" ]; then
    results+=("$(declare_result "$name" pass "$out")")
  else
    results+=("$(declare_result "$name" fail "$out")")
    overall_fail=1
  fi
}

run_check "wallet family-invariants" wallet/scripts/family-invariants.sh
run_check "browser family-invariants" browser/scripts/family-invariants.sh
run_check "scam-guard family-invariants" scam-guard/scripts/family-invariants.sh
run_check "contract-pin drift" scripts/pin-drift-check.sh

if [ "$FULL" = "1" ]; then
  run_check "wallet make ci" bash -c 'cd wallet && make ci'
  run_check "browser make ci" bash -c 'cd browser && cargo fmt --all -- --check && cargo clippy --workspace --all-targets -- -D warnings && cargo test --workspace'
  run_check "scam-guard make ci" bash -c 'cd scam-guard && make ci'
  run_check "system-test weave" ./system-test.sh
fi

# Assemble the JSON report.
{
  printf '{\n  "timestamp": "%s",\n  "full": %s,\n' "$TS" "$([ "$FULL" = 1 ] && echo true || echo false)"
  printf '  "wallet_sha": "%s",\n' "$(git -C wallet rev-parse HEAD 2>/dev/null || echo unknown)"
  printf '  "browser_sha": "%s",\n' "$(git -C browser rev-parse HEAD 2>/dev/null || echo unknown)"
  printf '  "scam_guard_sha": "%s",\n' "$(git -C scam-guard rev-parse HEAD 2>/dev/null || echo unknown)"
  printf '  "overall": "%s",\n' "$([ "$overall_fail" = 0 ] && echo pass || echo fail)"
  printf '  "checks": [%s]\n' "$(IFS=,; echo "${results[*]}")"
  printf '}\n'
} | jq . > "$REPORT"

echo ""
echo "============================================"
if [ "$overall_fail" = "0" ]; then
  echo "family-review: ALL CLEAR (report: $REPORT)"
else
  echo "family-review: FAILURES FOUND (report: $REPORT)" >&2
fi
exit "$overall_fail"
