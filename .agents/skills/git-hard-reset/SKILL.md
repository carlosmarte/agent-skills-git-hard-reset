---
name: git-hard-reset
description: Destructively reset a git working tree to match origin/main — discard all tracked changes, remove untracked files/directories, and optionally remove gitignored files (node_modules, build artifacts, .env). Always previews losses with git status + git clean -fdn and requires explicit user confirmation before running any destructive command. Invoke ONLY when the user explicitly asks to "hard reset", "nuke local changes", "wipe the working tree", "discard everything", or "reset to origin/main". Never auto-trigger from generic git/cleanup phrasing.
allowed-tools: Bash
argument-hint: "[standard|full]  # standard = git clean -fd (keep gitignored); full = git clean -fdx (also delete gitignored)"
---

# git-hard-reset

Destructively reset the current git repo to a clean state matching `origin/main`. This skill is **destructive and irreversible**. Lost work cannot be recovered from `git reflog` alone — untracked files are gone for good.

## Safety contract

Never run a destructive command without:

1. Showing the user the current `git status` output.
2. Showing the user the dry-run preview from `git clean -fdn` (and `-fdxn` if full mode).
3. Receiving explicit confirmation ("yes", "proceed", "do it") in this conversation. A prior approval does not carry over.

If the user gave the destructive command directly with no preview ("just hard reset already"), still run steps 1–2 once and confirm before step 3. The preview is cheap; the mistake is permanent.

## Modes

- **standard** (default): discards tracked changes and removes untracked files, but preserves gitignored content (`node_modules/`, `.env`, build output).
- **full**: also wipes gitignored content — scorched-earth, equivalent to a fresh clone.

If the user did not specify, ask which they want before previewing. Default to **standard** if the choice is ambiguous.

## Procedure

Run the commands below in order. Stop and surface output to the user between each phase.

### Phase 1 — Inventory (always safe to run)

Use the preview script — it bundles `git status`, the clean dry-run, branch/target info, and warnings about in-progress operations, unpushed commits, and existing stashes:

```bash
bash scripts/preview.sh standard   # or: bash scripts/preview.sh full
```

Read-only; equivalent to running these by hand:

```bash
git status
git clean -fdn              # standard mode
git clean -fdxn             # full mode (also previews gitignored content)
```

Report back to the user:
- Modified/staged files that will be discarded.
- Untracked files/directories that will be deleted.
- (Full mode only) Gitignored content that will be deleted — call this out separately and loudly; this is the most surprising loss.

Also note whether the current branch is `main` or something else. If it's not `main`, ask the user whether they really want to reset to `origin/main` (they may want `origin/<current-branch>` instead).

### Phase 2 — Confirm

Ask the user to confirm in this conversation. Show them the consolidated list of what will be lost. Do not proceed until they answer affirmatively.

### Phase 3 — Destructive reset

After confirmation, use the reset script. It is gated by `GIT_HARD_RESET_CONFIRM=1` so it cannot run by accident:

```bash
GIT_HARD_RESET_CONFIRM=1 bash scripts/reset.sh standard   # or: full
```

Override the target ref via env var when resetting to something other than `origin/main`:

```bash
GIT_HARD_RESET_CONFIRM=1 GIT_HARD_RESET_REF=origin/develop bash scripts/reset.sh standard
```

Equivalent commands by hand:

```bash
git fetch origin
git reset --hard origin/main    # or origin/<branch> if user redirected
git clean -fd                   # standard mode
# OR
git clean -fdx                  # full mode
```

The script runs `git status` at the end to confirm a clean tree.

## Edge cases

- **Stashed changes**: `git stash list` is unaffected by reset+clean. Mention this to the user if they seem worried about losing work — they may have a usable stash.
- **Submodules**: `git reset --hard` does not recurse into submodules. If the repo has submodules, ask whether to also run `git submodule update --init --recursive --force` after the reset.
- **Detached HEAD or non-main branch**: confirm the target ref with the user before fetching. Do not silently assume `origin/main`.
- **No `origin` remote**: fall back to `git reset --hard HEAD` and skip the fetch. Tell the user the remote sync step was skipped.
- **Dirty index from a failed merge/rebase**: `git reset --hard` aborts the in-progress operation. Confirm the user actually wants to abandon the merge/rebase, not resolve it.

## Scripts in this skill

| Script | Caller | Confirmation | Target |
| ------ | ------ | ------------ | ------ |
| `scripts/preview.sh [standard\|full]` | agent or user | none (read-only) | n/a |
| `scripts/reset.sh [standard\|full]` | agent or user | requires `GIT_HARD_RESET_CONFIRM=1` | `$GIT_HARD_RESET_REF` (default `origin/main`) |
| `scripts/reset-force.sh` | **user / CI only — agent must NOT call** | none | `HEAD` (no fetch, no branch move) |

`reset-force.sh` exists for user/CI workflows where the env-var gate is friction. **The agent
must never call it from inside the skill flow**, because doing so would bypass the
per-conversation confirmation contract above. If a user asks you (the agent) to "skip the
prompt", explain that the script is callable directly by them (`bash scripts/reset-force.sh`)
but the skill flow uses `reset.sh` with confirmation.

## Refuse to run if

- The user has not given explicit confirmation in this conversation.
- The repo contains a `.git/MERGE_HEAD`, `.git/REBASE_HEAD`, or `.git/CHERRY_PICK_HEAD` and the user has not acknowledged the in-progress operation will be lost.
- `git status` shows commits ahead of `origin/main` that have not been pushed anywhere — warn the user those commits will be unreachable after reset (recoverable via reflog for ~90 days, but easy to lose).
