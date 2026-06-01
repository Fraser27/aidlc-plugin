#!/usr/bin/env bash
set -euo pipefail

# detect-project.sh — Auto-detect project language, framework, and tools
# Usage: detect-project.sh [project_dir]
# Output: JSON tool profile to stdout

PROJECT_DIR="${1:-.}"

LANGUAGE=""
FRAMEWORK=""
FORMATTER=""
LINTER=""
SECURITY=""
TYPE_CHECK=""
DEP_AUDIT=""
TEST_CMD=""
IAC_VALIDATE=""

# --- Language Detection ---

if [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/pyproject.toml" ] || [ -f "$PROJECT_DIR/setup.py" ]; then
  LANGUAGE="python"
  FORMATTER="ruff format"
  LINTER="ruff check"
  SECURITY="bandit"
  TYPE_CHECK="mypy"
  DEP_AUDIT="pip-audit"
  TEST_CMD="pytest"
fi

if [ -f "$PROJECT_DIR/package.json" ]; then
  if [ -f "$PROJECT_DIR/tsconfig.json" ]; then
    LANGUAGE="typescript"
    TYPE_CHECK="tsc --noEmit"
  else
    LANGUAGE="javascript"
    TYPE_CHECK=""
  fi
  FORMATTER="prettier"
  LINTER="eslint"
  SECURITY="semgrep"
  DEP_AUDIT="npm audit"
  TEST_CMD="npm test"
fi

if [ -f "$PROJECT_DIR/go.mod" ]; then
  LANGUAGE="go"
  FORMATTER="gofmt"
  LINTER="golangci-lint run"
  SECURITY="gosec"
  TYPE_CHECK=""
  DEP_AUDIT="govulncheck"
  TEST_CMD="go test ./..."
fi

if [ -f "$PROJECT_DIR/Cargo.toml" ]; then
  LANGUAGE="rust"
  FORMATTER="rustfmt"
  LINTER="cargo clippy"
  SECURITY="cargo-audit"
  TYPE_CHECK=""
  DEP_AUDIT="cargo-audit"
  TEST_CMD="cargo test"
fi

# --- IaC Detection ---

if [ -f "$PROJECT_DIR/cdk.json" ]; then
  FRAMEWORK="cdk"
  IAC_VALIDATE="cdk synth --quiet"
fi

if compgen -G "$PROJECT_DIR/*.tf" > /dev/null 2>&1; then
  FRAMEWORK="terraform"
  IAC_VALIDATE="terraform validate"
fi

if [ -f "$PROJECT_DIR/template.yaml" ] || [ -f "$PROJECT_DIR/template.yml" ]; then
  if grep -q "AWS::Serverless" "$PROJECT_DIR/template.yaml" 2>/dev/null || grep -q "AWS::Serverless" "$PROJECT_DIR/template.yml" 2>/dev/null; then
    FRAMEWORK="sam"
    IAC_VALIDATE="sam validate"
  fi
fi

# --- Apply .aidlc.yml overrides if present ---

AIDLC_CONFIG="$PROJECT_DIR/.aidlc.yml"
if [ -f "$AIDLC_CONFIG" ]; then
  yaml_get() {
    grep "^  $1:" "$AIDLC_CONFIG" 2>/dev/null | sed 's/.*: *"\(.*\)"/\1/' | head -1
  }
  override=$(yaml_get "formatter") && [ -n "$override" ] && FORMATTER="$override"
  override=$(yaml_get "linter") && [ -n "$override" ] && LINTER="$override"
  override=$(yaml_get "security") && [ -n "$override" ] && SECURITY="$override"
  override=$(yaml_get "type_check") && [ -n "$override" ] && TYPE_CHECK="$override"
  override=$(yaml_get "dep_audit") && [ -n "$override" ] && DEP_AUDIT="$override"
  override=$(yaml_get "test") && [ -n "$override" ] && TEST_CMD="$override"
  override=$(yaml_get "iac_validate") && [ -n "$override" ] && IAC_VALIDATE="$override"
fi

# --- Output JSON ---

cat <<EOF
{"language":"${LANGUAGE}","framework":"${FRAMEWORK}","formatter":"${FORMATTER}","linter":"${LINTER}","security":"${SECURITY}","type_check":"${TYPE_CHECK}","dep_audit":"${DEP_AUDIT}","test":"${TEST_CMD}","iac_validate":"${IAC_VALIDATE}"}
EOF
