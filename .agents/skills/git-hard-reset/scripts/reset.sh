#!/usr/bin/env bash
# Destructively reset the working tree to a remote ref and remove untracked files.
# IRREVERSIBLE — untracked files are gone for good; ignored files too in full mode.
#
# Usage:
#   GIT_HARD_RESET_CONFIRM=1 bash scripts/reset.sh [standard|full]
#
# Environment:
#   GIT_HARD_RESET_CONFIRM  Must be set to "1" or the script refuses to run.
#   GIT_HARD_RESET_REF      Target ref to reset to. Default: origin/main.
#
# Modes:
#   standard  git clean -fd   (preserves gitignored content: node_modules, .env, build output)
#   full      git clean -fdx  (also removes gitignored content — scorched earth)
#
# Exit codes:
#   0  reset completed
#   1  confirmation env-var missing
#   2  bad arguments

set -euo pipefail

MODE="${1:-standard}"
case "$MODE" in
  standard|full) ;;
  *) echo "Usage: $0 [standard|full]" >&2; exit 2 ;;
esac

REF="${GIT_HARD_RESET_REF:-origin/main}"
CLEAN_FLAGS="-fd"
[ "$MODE" = "full" ] && CLEAN_FLAGS="-fdx"

if [ "${GIT_HARD_RESET_CONFIRM:-}" != "1" ]; then
  cat >&2 <<EOF
Refusing to run without explicit confirmation.

This would:
  1. git fetch origin
  2. git reset --hard $REF
  3. git clean $CLEAN_FLAGS

Re-run with confirmation:
  GIT_HARD_RESET_CONFIRM=1 $0 $MODE

Run scripts/preview.sh first to see what will be lost.
EOF
  exit 1
fi

echo "=== git fetch origin ==="
git fetch origin

echo "=== git reset --hard $REF ==="
git reset --hard "$REF"

echo "=== git clean $CLEAN_FLAGS ==="
git clean $CLEAN_FLAGS

echo ""
echo "=== Final state ==="
git status
