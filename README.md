# agent-skills-git-hard-reset

A single Agent Skill — **`git-hard-reset`** — packaged in the SKILL.md format. Destructively
resets a git working tree to match `origin/main`: discards tracked changes, removes untracked
files, and optionally wipes gitignored content. Always previews losses with `git status` +
`git clean -fdn` and refuses to run destructive commands without explicit confirmation.

The skill lives under `.agents/skills/git-hard-reset/` so the layout is runtime-neutral: any
agent loader that reads SKILL.md + YAML frontmatter (Claude Code, GitHub Copilot custom chat
modes, Cursor, Continue, raw prompt templates, …) can consume it.

## Install with `npx skills`

Uses the open [`skills`](https://github.com/vercel-labs/skills) CLI (supports Claude Code,
OpenCode, Codex, Cursor, Continue, and 50+ other agents). It already knows how to find skills
under `.agents/skills/`, so no extra config is needed.

```sh
# user-scoped: drops the skill under ~/<agent>/skills/ (available across every project)
npx skills add carlosmarte/agent-skills-git-hard-reset -g

# project-scoped: drops it under ./<agent>/skills/ in the current repo
npx skills add carlosmarte/agent-skills-git-hard-reset
```

Preview before installing:

```sh
npx skills add carlosmarte/agent-skills-git-hard-reset --list
```

Pin a specific agent runtime and run non-interactively (handy for CI):

```sh
npx skills add carlosmarte/agent-skills-git-hard-reset -g -a claude-code -y
```

Manage installed skills:

```sh
npx skills list                          # show what's installed
npx skills update git-hard-reset         # pull latest
npx skills remove git-hard-reset         # uninstall
```

Full CLI reference: [vercel-labs/skills](https://github.com/vercel-labs/skills).

## Alternative: clone and symlink manually

If you'd rather skip the loader CLI:

```sh
git clone https://github.com/carlosmarte/agent-skills-git-hard-reset.git ~/.agent-skills-git-hard-reset
ln -sf ~/.agent-skills-git-hard-reset/.agents/skills/git-hard-reset ~/.claude/skills/git-hard-reset
```

Or, if the repo is already checked out somewhere:

```sh
REPO="$(pwd)"
ln -sf "$REPO/.agents/skills/git-hard-reset" "$HOME/.claude/skills/git-hard-reset"
```

## Alternative: run the scripts directly via curl

The skill's scripts are self-contained shell. You can fetch and run them ad hoc without any
agent loader at all. Run inside the repo you want to reset:

```sh
# read-only preview (safe to run anytime)
curl -fsSL https://raw.githubusercontent.com/carlosmarte/agent-skills-git-hard-reset/main/.agents/skills/git-hard-reset/scripts/preview.sh | bash -s -- standard

# preview full mode (also previews -fdx — gitignored content removal)
curl -fsSL https://raw.githubusercontent.com/carlosmarte/agent-skills-git-hard-reset/main/.agents/skills/git-hard-reset/scripts/preview.sh | bash -s -- full

# destructive reset (refuses without GIT_HARD_RESET_CONFIRM=1)
curl -fsSL https://raw.githubusercontent.com/carlosmarte/agent-skills-git-hard-reset/main/.agents/skills/git-hard-reset/scripts/reset.sh \
  | GIT_HARD_RESET_CONFIRM=1 bash -s -- standard
```

Override the target ref when resetting to something other than `origin/main`:

```sh
curl -fsSL https://raw.githubusercontent.com/carlosmarte/agent-skills-git-hard-reset/main/.agents/skills/git-hard-reset/scripts/reset.sh \
  | GIT_HARD_RESET_CONFIRM=1 GIT_HARD_RESET_REF=origin/develop bash -s -- standard
```

## Which install path should I use?

| Scenario | Use |
| -------- | --- |
| You want the skill auto-discovered by Claude Code / Cursor / Copilot / etc. | `npx skills add` |
| You want a hermetic checkout you can `git pull` to update | `git clone` + manual symlink |
| You just need a one-shot reset from a remote machine, no install | `curl … \| bash` against `preview.sh` / `reset.sh` |

## The skill

| Skill | Purpose |
| ----- | ------- |
| [`git-hard-reset`](.agents/skills/git-hard-reset/SKILL.md) | Destructive reset to `origin/main` (or a chosen ref). Three-phase flow — inventory → confirm → destruct. Two modes: `standard` (preserves gitignored content) and `full` (also wipes gitignored content). |

### What it does

- **Phase 1 — Inventory** (`scripts/preview.sh`): runs `git status`, `git clean -fdn` (or `-fdxn` for full mode), reports the target ref, and warns about in-progress merges/rebases, unpushed commits, and existing stashes. Read-only.
- **Phase 2 — Confirm**: the agent shows the consolidated list of losses and waits for explicit "yes / proceed / do it" in the conversation. A prior approval does not carry over.
- **Phase 3 — Destruct** (`scripts/reset.sh`): runs `git fetch origin`, `git reset --hard $REF`, and `git clean -fd` (or `-fdx`). Hard-gated by `GIT_HARD_RESET_CONFIRM=1` so it cannot run by accident.

### Modes

- **`standard`** (default): discards tracked changes + untracked files. Preserves gitignored content (`node_modules/`, `.env`, build output).
- **`full`**: also wipes gitignored content. Scorched-earth — equivalent to a fresh clone.

## File shape

`SKILL.md` follows the [agent skill](https://agentskills.io) frontmatter contract:

```markdown
---
name: git-hard-reset              # must match directory name
description: <when + what>         # ≤ 1024 chars, trigger-keyword rich
allowed-tools: Bash
argument-hint: "[standard|full]"
---

# Title

Why → When to invoke → Safety contract → Procedure → Edge cases → Refuse-to-run conditions
```

## Loading into an agent runtime

### Claude Code

```sh
ln -sf "$(pwd)/.agents/skills/git-hard-reset" "$HOME/.claude/skills/git-hard-reset"
```

Then invoke as `/git-hard-reset` (or `/git-hard-reset full`).

### GitHub Copilot (VSCode custom chat modes)

Copy or symlink `.agents/skills/git-hard-reset/SKILL.md` into the consuming repo's
`.github/chatmodes/git-hard-reset.chatmode.md`, or into VSCode's global `User/prompts/`.

### Other runtimes / raw prompts

`cat .agents/skills/git-hard-reset/SKILL.md` and feed it as a system prompt. Frontmatter is
plain YAML; body is plain Markdown.

## Conventions

- **Skill name = directory name.** Validators reject mismatches.
- **The agent never runs destructive commands without explicit per-conversation confirmation.** The script-level gate (`GIT_HARD_RESET_CONFIRM=1`) is the second line of defense, not the first.
- **Scripts are usable standalone.** Both `preview.sh` and `reset.sh` are callable by the agent (per SKILL.md) *or* by the user directly via `bash` / `curl … | bash`. They do not depend on any kit-internal helpers.

## License

MIT (no `LICENSE` file in the repo yet — add one when ready).
