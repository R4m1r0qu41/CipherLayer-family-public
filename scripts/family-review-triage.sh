#!/usr/bin/env bash
# CipherLayer family review loop — Tier 1 trigger (CIPHERLAYER-FAMILY-
# GUIDE.md §7). Reads Tier 0's report and decides WHETHER a model needs to
# look at anything, and WHAT. It never calls a model itself — it only prints
# a decision. Cheap, deterministic, run after every family-review.sh.
#
# Escalates when either is true:
#   (a) the last Tier-0 report has a failing check;
#   (b) a security-sensitive path changed in any repo since the last time
#       this script was cleared (state in .family-review/state.json).
#
# Usage:
#   ./scripts/family-review-triage.sh           # decide + print guidance
#   ./scripts/family-review-triage.sh --clear    # after a human/model acted,
#                                                  advance the cleared-SHA
#                                                  watermark to current HEADs
#
# Exit codes: 0 = all clear, nothing to do. 2 = ESCALATE (see stdout for what
# and why). 1 = hard error (e.g. no report yet — run family-review.sh first).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

REPORT=".family-review/latest.json"
STATE=".family-review/state.json"

if [ ! -f "$REPORT" ]; then
  echo "no report at $REPORT — run ./scripts/family-review.sh first" >&2
  exit 1
fi
[ -f "$STATE" ] || echo '{}' > "$STATE"

# Security-sensitive path patterns per repo — a diff touching any of these
# always warrants a model's eyes, independent of whether Tier 0 passed.
wallet_sensitive='^(crates/cipherlayer-vault/|crates/cipherlayer-vaultd/|crates/cipherlayer-cli/src/serve\.rs|crates/cipherlayer-policy/|schemas/|docs/threat-model/|docs/security/|docs/adr/)'
browser_sensitive='^(crates/broker-core/|docs/threat-model/|docs/adr/|docs/architecture/trusted-confirmation-surface\.md|docs/architecture/browser-mvp-gate\.md)'
scam_guard_sensitive='^(crates/fpl-core/src/detectors/|registry/|docs/ADR-001|docs/RFC-)'

escalate=0
reasons=()

# (a) Any Tier-0 failure escalates immediately, whole report included.
overall="$(jq -r '.overall' "$REPORT")"
if [ "$overall" != "pass" ]; then
  escalate=1
  reasons+=("Tier-0 check(s) failing — see $REPORT")
fi

check_repo_diff() {
  local repo="$1" pattern="$2" key="$3"
  local cleared_sha current_sha
  cleared_sha="$(jq -r --arg k "$key" '.[$k].cleared_sha // empty' "$STATE")"
  current_sha="$(git -C "$repo" rev-parse HEAD 2>/dev/null || echo "")"
  [ -z "$current_sha" ] && return
  if [ -z "$cleared_sha" ]; then
    reasons+=("$repo: no prior watermark — first run, review current state then --clear")
    escalate=1
    return
  fi
  if [ "$cleared_sha" = "$current_sha" ]; then
    return
  fi
  if ! git -C "$repo" cat-file -e "$cleared_sha" 2>/dev/null; then
    reasons+=("$repo: watermark SHA $cleared_sha no longer reachable (history rewritten?) — review and --clear")
    escalate=1
    return
  fi
  local changed
  changed="$(git -C "$repo" diff --name-only "$cleared_sha" "$current_sha" -- . | grep -E "$pattern" || true)"
  if [ -n "$changed" ]; then
    escalate=1
    reasons+=("$repo: security-sensitive paths changed since $cleared_sha:"$'\n'"$(echo "$changed" | sed 's/^/    /')")
  fi
}

check_repo_diff wallet "$wallet_sensitive" wallet
check_repo_diff browser "$browser_sensitive" browser
check_repo_diff scam-guard "$scam_guard_sensitive" scam_guard

if [ "${1:-}" = "--clear" ]; then
  jq -n \
    --arg w "$(git -C wallet rev-parse HEAD 2>/dev/null || echo unknown)" \
    --arg b "$(git -C browser rev-parse HEAD 2>/dev/null || echo unknown)" \
    --arg s "$(git -C scam-guard rev-parse HEAD 2>/dev/null || echo unknown)" \
    '{wallet: {cleared_sha: $w}, browser: {cleared_sha: $b}, scam_guard: {cleared_sha: $s}}' \
    > "$STATE"
  echo "watermark cleared at current HEADs (wallet/browser/scam-guard)."
  exit 0
fi

if [ "$escalate" = "0" ]; then
  echo "family-review-triage: all clear — nothing needs model review."
  exit 0
fi

echo "family-review-triage: ESCALATE"
echo ""
for r in "${reasons[@]}"; do
  echo "  - $r"
done
echo ""
echo "Suggested next action: run /code-review or /security-review on the"
echo "flagged diff(s) above, or a manual read of the failing Tier-0 checks."
echo "After acting, run: ./scripts/family-review-triage.sh --clear"
exit 2
