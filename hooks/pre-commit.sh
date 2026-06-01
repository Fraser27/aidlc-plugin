#!/usr/bin/env bash
set -euo pipefail

# AIDLC pre-commit hook — format and lint staged files
# Blocks commit if unfixable lint errors remain

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/../scripts/detect-project.sh"
PROJECT_DIR="$(git rev-parse --show-toplevel)"

PROFILE=$("$DETECT" "$PROJECT_DIR")

json_get() {
  echo "$PROFILE" | grep -o "\"$1\":\"[^\"]*\"" | sed "s/\"$1\":\"\(.*\)\"/\1/"
}

FORMATTER=$(json_get "formatter")
LINTER=$(json_get "linter")

echo "[AIDLC] Running pre-commit checks..."

STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
if [ -z "$STAGED" ]; then
  exit 0
fi

# --- Format ---
if [ -n "$FORMATTER" ] && command -v "$(echo "$FORMATTER" | awk '{print $1}')" &>/dev/null; then
  echo "[AIDLC] Formatting..."
  (cd "$PROJECT_DIR" && eval "$FORMATTER .") 2>/dev/null || true
  echo "$STAGED" | while read -r file; do
    [ -f "$PROJECT_DIR/$file" ] && git add "$PROJECT_DIR/$file"
  done
fi

# --- Lint ---
if [ -n "$LINTER" ] && command -v "$(echo "$LINTER" | awk '{print $1}')" &>/dev/null; then
  echo "[AIDLC] Linting..."
  (cd "$PROJECT_DIR" && eval "$LINTER --fix ." 2>/dev/null) || true
  echo "$STAGED" | while read -r file; do
    [ -f "$PROJECT_DIR/$file" ] && git add "$PROJECT_DIR/$file"
  done
  if ! (cd "$PROJECT_DIR" && eval "$LINTER ." >/dev/null 2>&1); then
    echo "[AIDLC] Lint errors remain after auto-fix. Blocking commit."
    (cd "$PROJECT_DIR" && eval "$LINTER .") || true
    exit 1
  fi
fi

echo "[AIDLC] Pre-commit checks passed."
