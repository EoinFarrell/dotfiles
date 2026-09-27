# 3. Skill overlays for upstream Claude skills

## Status

Accepted

## Context

`git_setup.yaml`'s `claude_skill_repos` clones upstream skill repos (e.g.
`mattpocock/skills`, `cursor/plugins`) into `~/Code/claude/<repo>` with
`update: no`, and symlinks selected skills straight into
`~/.claude/skills` / `~/.agents/skills`. There was no way to locally tweak
a skill (fix a prompt, adjust a threshold) without forking the upstream
repo entirely — see issue #24.

Three constraints shaped the design:

- Skills with no local tweak must keep working exactly as today (plain
  symlink, zero overhead) — most skills will never need an overlay.
- A tweak must survive `~/Code/claude/<repo>` being deleted and
  re-cloned, so it can't live inside the clone.
- `update: no` means upstream only moves when a human deliberately runs
  `git pull` — at that point drift against an overlay is a realistic,
  rare event that must fail loudly rather than silently misapply.

## Decision

- **Overlay format**: one unified diff per skill, applied with
  `git apply` from the skill directory as cwd. This covers multi-file
  skill directories in a single file and gets "fails loudly on drift"
  for free via `git apply --check`, rather than inventing a custom
  structured-override format and conflict detector.
- **Overlay key**: the skill's destination symlink basename (e.g.
  `tdd.patch`), not its upstream repo-relative path. That basename is
  already the field that must be unique today — two skills can't both
  symlink to `~/.claude/skills/tdd` — so keying on it is a free
  uniqueness guarantee instead of a second one to maintain, and keeps
  overlay filenames flat instead of mirroring deep upstream paths.
- **Presence-as-config**: a skill's overlay path
  (`claude/skill-overlays/<basename>.patch`) is checked for existence at
  task-run time. Present → materialize (patch applied on top of the
  upstream clone, output written to `~/Code/claude/.build/<basename>/`,
  which is what gets symlinked). Absent → symlink straight to the
  upstream clone, unchanged. There is no separate registry list to keep
  in sync with the overlay directory's contents.
- **Build dir location**: `~/Code/claude/.build/<basename>/`, outside
  any git repo. It's disposable output derived from clone + patch state,
  not something to version-control or gitignore.
- **Diff basis**: patches are generated against whatever is currently in
  the upstream clone, not pinned to a recorded base commit/SHA. Given
  `update: no`, upstream only moves on a deliberate `git pull`, and
  `git apply --check` failing at that point is an acceptable, clearly
  attributable failure — proactive drift-tracking would be speculative
  bookkeeping for a rare event.
- **Failure scope**: a failing overlay is caught per-skill
  (`git apply --check`, `ignore_errors` + register), reported by name,
  and the play continues to the remaining skills; the playbook exits
  non-zero at the end if any skill failed. This surfaces every broken
  overlay in one run instead of whack-a-mole (fix one, rerun, hit the
  next).
- **Root/satellite precedence**: root `git_setup.yaml` stays satellite
  ([[$DOTFILES_WD]])-agnostic — it only ever applies overlays from this
  repo's own `claude/skill-overlays/`. The satellite's own playbook runs
  afterward (per `updateMachine`'s existing personal-then-satellite
  ordering, gated on `$DOTFILES_WD` existing) and, for any skill where it
  defines its own overlay of the same basename, re-materializes that
  skill from upstream + the satellite's overlay, overwriting the root's
  output outright. There is no patch-stacking — the satellite's overlay
  wins wholesale, never combined with the root's, matching the "fail
  loudly, don't silently misapply" principle: two independently-drifting
  patches applied in sequence would be exactly that failure mode.

## Consequences

- Adding a personal tweak to a skill is: generate a diff, save it at
  `claude/skill-overlays/<basename>.patch`. No playbook or task-file
  edit required.
- The satellite repo defining an overlay for a skill the root also
  overlays means the root's version is simply never used on that
  machine — there's no visible warning that it was shadowed. Acceptable
  since it's a single-user setup and the shadowing is deliberate
  ("work's tweak matters more here").
- If upstream is `git pull`ed and a patch no longer applies, provisioning
  reports that skill as broken and continues with the rest, but that
  skill's `~/.claude/skills` entry is left stale (whatever it was before
  this run) until the overlay is reconciled by hand.
