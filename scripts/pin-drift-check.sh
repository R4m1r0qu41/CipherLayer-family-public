#!/usr/bin/env bash
# Contract-pin drift check (Tier 0, family review loop — CIPHERLAYER-FAMILY-
# GUIDE.md §7). For every consumer's imports/<sibling>/PIN.json, verifies:
#   (a) the locally copied file's hash matches what PIN.json recorded
#       (catches a hand-edited pinned copy — pins are read-only by convention,
#       ADR-002);
#   (b) the producer's CURRENT exports/ hash still matches what was pinned
#       (catches the producer changing a contract without the consumer
#       re-pinning — a real integration hazard the family has hit before,
#       e.g. the nullable signing_request_id fix).
# Deterministic, offline, no model. Handles both PIN.json layouts in use:
# the bundle style (top-level files_sha256 map) and the per-pin style
# (pins[].hash + pins[].source_path, one file per pin).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check_bundle_style() {
  local pin_json="$1" import_dir="$2" producer_root="$3"
  local src_path
  src_path="$(jq -r '.pins[0].source_path' "$pin_json")"
  while read -r fname expected; do
    local local_file="$import_dir/$fname"
    local producer_file="$producer_root/$src_path$fname"
    local local_hash producer_hash
    local_hash="$(shasum -a 256 "$local_file" 2>/dev/null | awk '{print $1}')"
    if [ "$local_hash" != "$expected" ]; then
      echo "  FAIL $fname: local copy does not match PIN.json's recorded hash"
      fail=1
      continue
    fi
    if [ -f "$producer_file" ]; then
      producer_hash="$(shasum -a 256 "$producer_file" 2>/dev/null | awk '{print $1}')"
      if [ "$producer_hash" != "$expected" ]; then
        echo "  DRIFT $fname: producer's current export differs from what was pinned — re-pin or review the change"
        fail=1
        continue
      fi
    fi
    echo "  OK   $fname"
  done < <(jq -r '.files_sha256 | to_entries[] | "\(.key) \(.value)"' "$pin_json")
}

check_per_pin_style() {
  local pin_json="$1" import_dir="$2" producer_root="$3"
  while read -r src_path expected; do
    local fname
    fname="$(basename "$src_path")"
    local local_file="$import_dir/$fname"
    local producer_file="$producer_root/$src_path"
    local local_hash producer_hash
    local_hash="$(shasum -a 256 "$local_file" 2>/dev/null | awk '{print $1}')"
    if [ "$local_hash" != "$expected" ]; then
      echo "  FAIL $fname: local copy does not match PIN.json's recorded hash"
      fail=1
      continue
    fi
    if [ -f "$producer_file" ]; then
      producer_hash="$(shasum -a 256 "$producer_file" 2>/dev/null | awk '{print $1}')"
      if [ "$producer_hash" != "$expected" ]; then
        echo "  DRIFT $fname: producer's current export differs from what was pinned — re-pin or review the change"
        fail=1
        continue
      fi
    fi
    echo "  OK   $fname"
  done < <(jq -r '.pins[] | "\(.source_path) \(.hash | sub("^sha256:";""))"' "$pin_json")
}

echo "== contract-pin drift check =="
while read -r pin_json; do
  import_dir="$(dirname "$pin_json")"
  source_repo="$(jq -r '.source_repo' "$pin_json")"
  producer_root="$ROOT/$(basename "$source_repo")"
  echo "-- ${pin_json#"$ROOT"/} (producer: $(basename "$producer_root")) --"
  if jq -e '.files_sha256' "$pin_json" >/dev/null 2>&1; then
    check_bundle_style "$pin_json" "$import_dir" "$producer_root"
  else
    check_per_pin_style "$pin_json" "$import_dir" "$producer_root"
  fi
done < <(find "$ROOT"/*/imports -name PIN.json 2>/dev/null | sort)

if [ "$fail" = "0" ]; then
  echo "pin-drift-check: PASS"
else
  echo "pin-drift-check: FAIL" >&2
fi
exit "$fail"
