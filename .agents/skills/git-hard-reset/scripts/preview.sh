#!/usr/bin/env bash
# Preview what `git-hard-reset` would destroy. Read-only — safe to run anytime.
#
# Usage:
#   bash scripts/preview.sh [standard|full]
#
# Modes:
#   standard  Show tracked changes + untracked files that `git clean -fd` would remove.
#   full      Also show gitignored content that `git clean -fdx` would remove.
#
# Exit codes:
#   0  preview rendered
#   2  bad arguments

set -euo pipefail

MODE="${1:-standard}"
case "$MODE" in
  standard|full) ;;
  *) echo "Usage: $0 [standard|full]" >&2; exit 2 ;;
esac

echo "=== Branch and target ==="
echo "current branch: $(git rev-parse --abbrev-ref HEAD)"
echo "origin url:     $(git remote get-url origin 2>/dev/null || echo '(no origin)')"
echo "target ref:     ${GIT_HARD_RESET_REF:-origin/main}"
echo ""

echo "=== git status ==="
git status
echo ""

echo "=== Untracked files git clean -fd would delete ==="
git clean -fdn
echo ""

if [ "$MODE" = "full" ]; then
  echo "=== ALSO deleted in full mode (gitignored content via git clean -fdx) ==="
  git clean -fdxn
  echo ""
fi

# Surface things that are easy to lose without realizing it.
for marker in MERGE_HEAD REBASE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
  if [ -e ".git/$marker" ]; then
    echo "WARNING: in-progress operation detected (.git/$marker) — will be aborted on reset."
  fi
done

target_ref="${GIT_HARD_RESET_REF:-origin/main}"
if git rev-parse --verify "$target_ref" >/dev/null 2>&1; then
  ahead=$(git rev-list --count "$target_ref"..HEAD 2>/dev/null || echo 0)
  if [ "$ahead" -gt 0 ] 2>/dev/null; then
    echo "WARNING: HEAD has $ahead commit(s) not in $target_ref — they will become unreachable after reset (recoverable from reflog for ~90 days)."
  fi
fi

if git stash list 2>/dev/null | grep -q .; then
  echo "NOTE: stashes are unaffected by reset/clean — \`git stash list\` will survive."
fi
