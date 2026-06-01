#!/usr/bin/env bash
set -euo pipefail

# AIDLC post-commit hook — run security scan on changed files (warn only)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/../scripts/detect-project.sh"
PROJECT_DIR="$(git rev-parse --show-toplevel)"

PROFILE=$("$DETECT" "$PROJECT_DIR")

json_get() {
  echo "$PROFILE" | grep -o "\"$1\":\"[^\"]*\"" | sed "s/\"$1\":\"\(.*\)\"/\1/"
}

SECURITY=$(json_get "security")

if [ -z "$SECURITY" ]; then
  exit 0
fi

SECURITY_CMD=$(echo "$SECURITY" | awk '{print $1}')
if ! command -v "$SECURITY_CMD" &>/dev/null; then
  exit 0
fi

CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || true)
if [ -z "$CHANGED" ]; then
  exit 0
fi

echo "[AIDLC] Running security scan on committed files..."

OUTPUT=$(cd "$PROJECT_DIR" && eval "$SECURITY -r ." 2>&1) || true

if echo "$OUTPUT" | grep -qiE "(high|critical|severe)"; then
  echo "[AIDLC] WARNING: Security findings detected in committed code."
  echo "$OUTPUT" | head -20
  echo "[AIDLC] Run '/aidlc-review' for full analysis."
fi
