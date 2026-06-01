#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_CHECKS="$SCRIPT_DIR/../scripts/run-checks.sh"
PASS=0
FAIL=0

assert_json_field() {
  local output="$1" field="$2" context="$3"
  if echo "$output" | grep -q "\"check\":\"$field\""; then
    PASS=$((PASS + 1))
  else
    echo "FAIL [$context]: expected check '$field' in output"
    echo "  Got: $output"
    FAIL=$((FAIL + 1))
  fi
}

# Test with a mock profile (dry-run mode)
echo "--- Testing check runner dry-run ---"
output=$("$RUN_CHECKS" --dry-run --profile '{"language":"python","framework":"cdk","formatter":"ruff format","linter":"ruff check","security":"bandit","type_check":"mypy","dep_audit":"pip-audit","test":"pytest","iac_validate":"cdk synth --quiet"}')
assert_json_field "$output" "format" "format check listed"
assert_json_field "$output" "lint" "lint check listed"
assert_json_field "$output" "security" "security check listed"
assert_json_field "$output" "type_check" "type check listed"
assert_json_field "$output" "test" "test check listed"
assert_json_field "$output" "dep_audit" "dep audit listed"
assert_json_field "$output" "iac_validate" "iac check listed"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
