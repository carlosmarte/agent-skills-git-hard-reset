#!/usr/bin/env bash
# Force-discard uncommitted work — NO CONFIRMATION PROMPT, NO ENV-VAR GATE.
# IRREVERSIBLE — untracked files are gone for good.
#
# Usage:
#   bash scripts/reset-force.sh
#
# What it does:
#   git status                  # show what's about to be lost
#   git reset --hard HEAD       # discard tracked changes
#   git clean -fdn              # preview untracked removal (informational)
#   git clean -fd               # remove untracked files/directories
#
# Differences from scripts/reset.sh:
#   - Resets to HEAD (the current commit), NOT origin/main. Does NOT fetch; does NOT
#     move the branch. Committed work on the current branch is preserved.
#   - No GIT_HARD_RESET_CONFIRM gate. Runs immediately.
#   - No standard/full mode flag. Equivalent to `reset.sh standard` minus the remote sync.
#
# When to use this instead of reset.sh:
#   - CI / scripted workflows where the env-var prompt is friction.
#   - Dev loops where you know the branch position is right and only want a clean tree.
#
# When NOT to use it:
#   - Interactive sessions where you might confuse "discard uncommitted" with "sync to remote".
#     Use scripts/reset.sh — it forces you to set GIT_HARD_RESET_CONFIRM=1 and gives you
#     time to read the preview first.
#   - Agent-driven flows. The git-hard-reset skill MUST use scripts/reset.sh so the safety
#     contract (preview + per-conversation confirmation) holds.

set -euo pipefail

echo "=== git status (about to be discarded below) ==="
git status

echo ""
echo "=== git reset --hard HEAD ==="
git reset --hard HEAD

echo ""
echo "=== Untracked files that will be removed (git clean -fdn preview) ==="
git clean -fdn

echo ""
echo "=== git clean -fd ==="
git clean -fd

echo ""
echo "=== Final state ==="
git status
