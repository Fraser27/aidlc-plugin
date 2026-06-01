#!/usr/bin/env bash
set -euo pipefail

# run-checks.sh — Execute all relevant checks based on project profile
# Usage: run-checks.sh [--dry-run] [--profile JSON] [--dir PROJECT_DIR]
# Output: One JSON object per line per check

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
PROFILE=""
PROJECT_DIR="."

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --dir) PROJECT_DIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# If no profile provided, detect it
if [ -z "$PROFILE" ]; then
  PROFILE=$("$SCRIPT_DIR/detect-project.sh" "$PROJECT_DIR")
fi

# Extract fields from profile JSON
json_get() {
  echo "$PROFILE" | grep -o "\"$1\":\"[^\"]*\"" | sed "s/\"$1\":\"\(.*\)\"/\1/"
}

FORMATTER=$(json_get "formatter")
LINTER=$(json_get "linter")
SECURITY=$(json_get "security")
TYPE_CHECK=$(json_get "type_check")
DEP_AUDIT=$(json_get "dep_audit")
TEST_CMD=$(json_get "test")
IAC_VALIDATE=$(json_get "iac_validate")

run_check() {
  local check_name="$1" tool="$2" command="$3"

  if [ -z "$tool" ]; then
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "{\"check\":\"$check_name\",\"tool\":\"$tool\",\"command\":\"$command\",\"status\":\"dry-run\",\"findings\":[]}"
    return
  fi

  local output exit_code
  output=$(cd "$PROJECT_DIR" && eval "$command" 2>&1) && exit_code=0 || exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo "{\"check\":\"$check_name\",\"tool\":\"$tool\",\"status\":\"pass\",\"findings\":[]}"
  else
    local msg
    msg=$(echo "$output" | head -20 | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo '"check failed"')
    echo "{\"check\":\"$check_name\",\"tool\":\"$tool\",\"status\":\"findings\",\"findings\":[{\"severity\":\"medium\",\"message\":$msg}]}"
  fi
}

# Execute checks in order
run_check "format" "$FORMATTER" "$FORMATTER ."
run_check "lint" "$LINTER" "$LINTER ."
run_check "type_check" "$TYPE_CHECK" "$TYPE_CHECK ."
run_check "test" "$TEST_CMD" "$TEST_CMD"
run_check "security" "$SECURITY" "$SECURITY -r ."
run_check "dep_audit" "$DEP_AUDIT" "$DEP_AUDIT"
run_check "iac_validate" "$IAC_VALIDATE" "$IAC_VALIDATE"
