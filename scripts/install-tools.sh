#!/usr/bin/env bash
set -euo pipefail

# install-tools.sh — Check for and install missing tools
# Usage: install-tools.sh [--profile JSON] [--auto]
# --auto: install without prompting (for CI)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE=""
AUTO=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --profile) PROFILE="$2"; shift 2 ;;
    --auto) AUTO=true; shift ;;
    *) shift ;;
  esac
done

if [ -z "$PROFILE" ]; then
  PROFILE=$("$SCRIPT_DIR/detect-project.sh" ".")
fi

json_get() {
  echo "$PROFILE" | grep -o "\"$1\":\"[^\"]*\"" | sed "s/\"$1\":\"\(.*\)\"/\1/"
}

LANGUAGE=$(json_get "language")
MISSING=()

check_tool() {
  local tool_name="$1" binary="$2"
  if [ -z "$binary" ]; then return; fi
  local cmd
  cmd=$(echo "$binary" | awk '{print $1}')
  if ! command -v "$cmd" &>/dev/null; then
    MISSING+=("$tool_name:$binary")
    echo "MISSING: $cmd (needed for $tool_name)"
  else
    echo "OK: $cmd"
  fi
}

echo "=== Checking tools for $LANGUAGE project ==="
check_tool "formatter" "$(json_get 'formatter')"
check_tool "linter" "$(json_get 'linter')"
check_tool "security" "$(json_get 'security')"
check_tool "type_check" "$(json_get 'type_check')"
check_tool "dep_audit" "$(json_get 'dep_audit')"
check_tool "test" "$(json_get 'test')"
check_tool "iac_validate" "$(json_get 'iac_validate')"

if [ ${#MISSING[@]} -eq 0 ]; then
  echo ""
  echo "All tools installed."
  exit 0
fi

echo ""
echo "=== Missing tools ==="
for item in "${MISSING[@]}"; do
  echo "  - ${item%%:*}: ${item##*:}"
done

echo ""
echo "=== Suggested install commands ==="
case "$LANGUAGE" in
  python)
    echo "pip install ruff bandit mypy pip-audit pytest pytest-cov"
    if [ "$AUTO" = true ]; then
      pip install ruff bandit mypy pip-audit pytest pytest-cov
    fi
    ;;
  typescript|javascript)
    echo "npm install -D prettier eslint typescript @semgrep/cli"
    if [ "$AUTO" = true ]; then
      npm install -D prettier eslint typescript
    fi
    ;;
  go)
    echo "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    echo "go install github.com/securego/gosec/v2/cmd/gosec@latest"
    echo "go install golang.org/x/vuln/cmd/govulncheck@latest"
    if [ "$AUTO" = true ]; then
      go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
      go install github.com/securego/gosec/v2/cmd/gosec@latest
      go install golang.org/x/vuln/cmd/govulncheck@latest
    fi
    ;;
  rust)
    echo "rustup component add rustfmt clippy"
    echo "cargo install cargo-audit"
    if [ "$AUTO" = true ]; then
      rustup component add rustfmt clippy
      cargo install cargo-audit
    fi
    ;;
esac
