# Context: dotfiles

## Glossary

**Root repo** — `~/Code/personal/dotfiles` (`$DOTFILES`). Bootstraps standalone: its `zsh/startup/init.sh` sets up the shell environment, exports `$DOTFILES_WD`, and sources the satellite repo if present. Defines shared machinery (sops helpers, `getLatestFromGit`, symlink conventions, docs format) that the satellite reuses rather than duplicates. Used on multiple personal machines: a macOS laptop, and two Debian boxes — `nr200p` (desktop) and `t480` (laptop).

**Satellite repo** — `~/Code/workday/eoin-farrell/dotfiles` (`$DOTFILES_WD`). Work-specific overlay, used only on the work laptop. Cannot bootstrap on its own — it relies on being sourced by the root repo's `init.sh`, and calls back into root-defined helpers (`_sops_decrypt_if_changed`, `getLatestFromGit`, `sops-watch.sh`). A satellite depends on its root; a root never depends on a satellite.

**`$DOTFILES_WD`** — the single canonical env var naming the satellite repo's path. (Historical aliases `WDDOTFILES` / `WdDOTFILESD` have been removed — one name per concept.)

**Upstream skill repo** — one of `claude_skill_repos` (e.g. `mattpocock/skills`, `cursor/plugins`), cloned read-only into `~/Code/claude/<repo>` with `update: no`. Content is used verbatim unless a skill overlay applies. Never edited in place — a needed change is expressed as an overlay in this repo (or the satellite repo) instead.

**Skill overlay** — a unified diff, keyed by a skill's destination symlink basename (e.g. `claude/skill-overlays/tdd.patch`), that patches an upstream skill directory's content before it's linked. A skill with no overlay file present is symlinked straight from its upstream clone, unchanged. Root-repo overlays cover personal tweaks; the satellite repo can define its own overlay of the same name, which wins outright over the root's overlay for that skill (no stacking) — see [[0003-skill-overlays-for-upstream-claude-skills]].

**Materialized skill** — the result of applying a skill overlay to an upstream skill directory, written to a build directory outside any git repo (`~/Code/claude/.build/<skill-name>/`), which is what actually gets symlinked into `~/.claude/skills` / `~/.agents/skills` in the overlay case.
