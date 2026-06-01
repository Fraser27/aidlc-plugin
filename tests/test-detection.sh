#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/../scripts/detect-project.sh"
FIXTURES="$SCRIPT_DIR/fixtures"
PASS=0
FAIL=0

assert_contains() {
  local output="$1" expected="$2" context="$3"
  if echo "$output" | grep -q "$expected"; then
    PASS=$((PASS + 1))
  else
    echo "FAIL [$context]: expected '$expected' in output"
    echo "  Got: $output"
    FAIL=$((FAIL + 1))
  fi
}

# Test Python CDK detection
echo "--- Testing Python CDK detection ---"
output=$("$DETECT" "$FIXTURES/python-cdk")
assert_contains "$output" '"language":"python"' "python-cdk language"
assert_contains "$output" '"formatter":"ruff format"' "python-cdk formatter"
assert_contains "$output" '"iac_validate":"cdk synth --quiet"' "python-cdk iac"
assert_contains "$output" '"security":"bandit"' "python-cdk security"

# Test TypeScript Next detection
echo "--- Testing TypeScript Next detection ---"
output=$("$DETECT" "$FIXTURES/typescript-next")
assert_contains "$output" '"language":"typescript"' "ts-next language"
assert_contains "$output" '"formatter":"prettier"' "ts-next formatter"
assert_contains "$output" '"linter":"eslint"' "ts-next linter"

# Test Go Terraform detection
echo "--- Testing Go Terraform detection ---"
output=$("$DETECT" "$FIXTURES/go-terraform")
assert_contains "$output" '"language":"go"' "go-tf language"
assert_contains "$output" '"formatter":"gofmt"' "go-tf formatter"
assert_contains "$output" '"iac_validate":"terraform validate"' "go-tf iac"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
