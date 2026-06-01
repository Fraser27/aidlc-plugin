#!/usr/bin/env bash
set -euo pipefail

# severity-filter.sh — Filter check findings by severity level
# Usage: echo '<check_output>' | severity-filter.sh --level high [--exit-code]
# Levels: high (high+critical), medium (medium+high+critical), all
# --exit-code: exit non-zero if blocking findings exist at the specified level

LEVEL="high"
EXIT_CODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --level) LEVEL="$2"; shift 2 ;;
    --exit-code) EXIT_CODE=true; shift ;;
    *) shift ;;
  esac
done

# Read all input
INPUT=$(cat)

# Define severity patterns based on level
case "$LEVEL" in
  high)    PATTERN='"severity":"(high|critical)"' ;;
  medium)  PATTERN='"severity":"(high|critical|medium)"' ;;
  all)     PATTERN='"severity":"(high|critical|medium|low)"' ;;
  *)       echo "Unknown level: $LEVEL" >&2; exit 2 ;;
esac

# Filter and output matching findings
FILTERED=$(echo "$INPUT" | grep -oE '\{"severity":"[^"]+","message":"[^"]*"\}' | grep -E "$PATTERN" || true)

if [ -n "$FILTERED" ]; then
  echo "$FILTERED"
  if [ "$EXIT_CODE" = true ]; then
    exit 1
  fi
else
  if [ "$EXIT_CODE" = true ]; then
    exit 0
  fi
fi
