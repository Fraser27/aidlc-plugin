#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER="$SCRIPT_DIR/../scripts/severity-filter.sh"
PASS=0
FAIL=0

assert_eq() {
  local actual="$1" expected="$2" context="$3"
  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL [$context]: expected '$expected', got '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

# Test filtering high findings
echo "--- Testing severity filter ---"
INPUT='{"check":"security","tool":"bandit","status":"findings","findings":[{"severity":"high","message":"eval detected"},{"severity":"low","message":"naming"}]}'

high_count=$(echo "$INPUT" | "$FILTER" --level high | grep -c '"severity":"high"' || echo "0")
assert_eq "$high_count" "1" "high filter count"

all_count=$(echo "$INPUT" | "$FILTER" --level all | grep -c '"severity"' || echo "0")
assert_eq "$all_count" "2" "all filter count"

# Test exit code (should be non-zero if blocking findings exist)
echo "$INPUT" | "$FILTER" --level high --exit-code && ec=$? || ec=$?
assert_eq "$ec" "1" "exit code on high findings"

CLEAN='{"check":"lint","tool":"ruff","status":"pass","findings":[]}'
echo "$CLEAN" | "$FILTER" --level high --exit-code && ec=$? || ec=$?
assert_eq "$ec" "0" "exit code on clean"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
