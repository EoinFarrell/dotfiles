# Dotfiles Consistency & Portability Overhaul

---

## Phase 0 (do first, standalone) — Single `updateMachine` command

Independent of the overhaul below and safe to ship on its own. Replaces the current
`getLatestPackages && getLatestPackagesWD` habit with one auto-detecting command that
also closes real gaps in what "up to date" means.

### Why — gaps in today's routine

- **Neither function `git pull`s the dotfiles repos themselves** — they pull plugins and
  external tool repos, then re-run Ansible from possibly-stale local dotfiles. (CLAUDE.md
  wrongly claims `getLatestPackages` pulls latest from git.)
- **`base_setup.yaml` is never run by the update routine** — only `git_setup.yaml` is. So
  newly-*added* casks / formulae (`ansible/vars/homebrew_packages.yml`) and asdf tool
  versions never install; `brew upgrade` only upgrades what's already present.
- **`asdf update` updates asdf core, not the runtimes** pinned in `.tool-versions`
  (that `asdf install` step only lives in `base_setup.yaml`).
- **Brew upgrade is gated behind `if switch -v kubectl`** (`zsh/functions.sh:53`) — a
  copy-paste leftover coupling Homebrew upgrades to kubeswitch being installed. Bug.
- **`getLatestPackagesWD` has no internet check** and blindly `cd`s/builds CLIs.

### Design (decided: one auto-detecting name, fix gaps + wrap)

Define `updateMachine` in the personal repo (`zsh/functions.sh`). Same command on every
machine; the work half runs only when `$DOTFILES_WD` exists (i.e. the work laptop).

Order of operations:
1. Internet check (reuse `isInternetAvailable`); bail early if offline.
2. `git pull --ff-only` the personal dotfiles repo; if `$DOTFILES_WD` exists, pull it too.
3. `getLatestPackages` (personal) with the `switch -v kubectl` brew gate **removed** so
   `brew outdated | go run script.go | xargs brew upgrade` runs whenever brew is present.
4. Run **`base_setup.yaml`** (installs newly-declared casks/formulae/fonts + asdf tool
   versions) **then** `git_setup.yaml` (symlinks/clones) — both `--connection=local`.
   Guard `base_setup.yaml` to the right OS (it has a Debian variant `base_setup_debian.yaml`).
5. If `$DOTFILES_WD` exists: `getLatestPackagesWD` (add an `isInternetAvailable` guard).

Keep `getLatestPackages` / `getLatestPackagesWD` as callable building blocks; `updateMachine`
orchestrates them. Pass `--skip-ansible` into the inner functions where `updateMachine` now
owns the Ansible run, to avoid running the playbooks twice.

Also fix the CLAUDE.md line that claims the old command git-pulls, and update it to point at
`updateMachine`.

### Verification

- `updateMachine` on a personal machine: pulls only personal repo, runs both personal
  playbooks, does not attempt the WD half (`$DOTFILES_WD` absent → skipped).
- On the work laptop: pulls both repos, runs personal playbooks + WD build/playbook.
- Add a brand-new formula to `homebrew_packages.yml`, run `updateMachine`, confirm it
  installs (proves the base_setup gap is closed) — previously it would not.
- `--check` the playbooks first to confirm no unexpected symlink churn.

---

## Context

Two dotfiles repos manage the full machine setup:

- **Personal** — `~/Code/personal/dotfiles` (`$DOTFILES`). Used on **multiple** personal machines (a macOS laptop, plus two Debian boxes — desktop `nr200p` and laptop `t480`). It is the bootstrap root: its `zsh/startup/init.sh` sets `$DOTFILES_WD` and sources the work repo.
- **Work** — `~/Code/workday/eoin-farrell/dotfiles` (`$DOTFILES_WD`). Used **only on this work laptop** (and future laptop upgrades). It is a *satellite* — it cannot bootstrap standalone and relies on the personal repo for `_sops_decrypt_if_changed`, `getLatestFromGit`, `sops-watch.sh`, and for being sourced at all.

The two repos have drifted. The work repo hardcodes `/Users/eoin.farrell/...` absolute paths in several places (so it won't survive a laptop upgrade with a different username, and even the current user is fragile), duplicates structure without sharing conventions, and lacks the personal repo's documentation scaffolding. The goal of this change is to make the two repos **structurally consistent** and the work repo **portable to a future laptop** — while respecting that the personal repo is the parent and the work repo is a thin, sourced overlay.

This plan is a comprehensive, staged overhaul focused on the two chosen areas: **cross-repo consistency** and **portability**. It is intentionally low-risk-first: each phase is independently shippable and verifiable.

---

## Guiding principles

1. **Personal is the parent, work is the overlay.** Shared machinery (sops helpers, `getLatestFromGit`, symlink conventions, docs format) is *defined* in personal and *reused* by work. Never duplicate a helper into the work repo.
2. **No hardcoded absolute user paths.** Everything derives from `$HOME`, `$DOTFILES`, `$DOTFILES_WD`, or an Ansible variable. `~` expansion or `${HOME}` only.
3. **One name per concept.** Kill the `DOTFILES_WD` / `WDDOTFILES` / `WdDOTFILESD` triple.
4. **Same conventions in both repos** — config-file naming, ansible symlink pattern, docs layout.

---

## Phase 1 — Portability: eliminate hardcoded absolute paths (work repo)

The blocker for a laptop upgrade. All of these live under `$DOTFILES_WD`, which is already exported by the personal `init.sh` before the work repo is sourced, so it is always available to work shell scripts.

- **`envStart/base.sh:3-4`** — replace the `# TODO: CHANGE ME` hardcoded `ENV_START_DIR=/Users/eoin.farrell/.../envStart` with `ENV_START_DIR="$DOTFILES_WD/envStart"`. Remove the TODO.
- **`ansible/setup.yaml`** — the symlink `loop` (lines 31-43) and every `find:`/`regex_replace` path (lines 47-133) hardcode `~/Code/workday/eoin-farrell/dotfiles/...` and `~/Code/workday/...`. Introduce play-level `vars:` (`dotfiles_wd`, `wd_tools`, `mia_root`) and template every path off them. `~` is fine for `$HOME`-relative dests; the repo root must be a var so a relocated checkout still works.
- **`kubeswitch/switch-config.yaml`**, **`aws/config`**, and any `envStart/connectivity/*.sh` with literal `/Users/eoin.farrell/...` — audit and replace with `$HOME`/`$DOTFILES_WD` where the file is shell-sourced. NOTE: `switch-config.yaml` and `aws/config` are consumed by external tools (kubeswitch, awscli) that do **not** do shell expansion — for those, prefer `~` (both tools expand it) or document why a literal is required. Verify per-file before editing.
- Grep gate for the whole repo: `grep -rn '/Users/eoin.farrell' .` must return only files that are genuinely non-expandable (with a comment explaining each remaining case).

Representative files: `envStart/base.sh`, `ansible/setup.yaml`, `kubeswitch/switch-config.yaml`, `aws/config`.

## Phase 2 — Consistency: unify the `$DOTFILES_WD` naming

- **`zsh/startup/init.sh:6-8`** (personal) — keep `DOTFILES_WD` as the single canonical name; delete `WDDOTFILES` and `WdDOTFILESD`.
- Grep both repos for `WDDOTFILES` / `WdDOTFILESD` and rewrite each use to `DOTFILES_WD` (`grep -rn 'WDDOTFILES\|WdDOTFILESD'` across `$DOTFILES` and `$DOTFILES_WD`). Expected hotspots: `zsh/workday-functions.sh`, `envStart/*`.
- Export `DOTFILES`, `DOTFILES_WD`, `CODE`, `PERSONAL` (personal `init.sh` currently assigns several without `export`, so sub-shells/ansible `shell:` steps re-derive them — see `ansible/setup.yaml:136-139` which re-exports them by hand). Exporting once removes that duplication.

## Phase 3 — Consistency: one cross-platform entry playbook with OS/host fan-out

### Why (findings from the Ansible review)

There are 7 playbooks across the two repos. What they actually do:

| Playbook | Target | Invoked by | Status |
|---|---|---|---|
| `base_setup.yaml` (personal) | macOS local | `updateMachine` (`uname`=Darwin branch) | active |
| `base_setup_debian.yaml` (personal) | Debian local (nr200p) | `updateMachine` (`uname`=Linux branch) | active |
| `git_setup.yaml` (personal) | local | `getLatestPackages` / `updateMachine` | active |
| `setup.yaml` (workday) | macOS work laptop | `getLatestPackagesWD` | active |
| `claude.yaml` (personal) | local | **no caller** (manual) | orphaned — best pattern in the repo |
| `tldr_setup.yaml` (personal) | macOS local | **no caller** (manual) | stale/niche |
| `nvidia_setup.yaml` (personal) | **nr200p over SSH** | manual `-Kk` | keep as-is (one-off GPU) |

Key facts driving the design:
- `updateMachine` currently branches on `uname -s` to pick `base_setup.yaml` vs `base_setup_debian.yaml`, then calls `git_setup.yaml` — **two playbook names selected in shell**. This is exactly the fan-out Ansible should own via `ansible_os_family`.
- The two `base_setup*` playbooks **already share** their two most important steps — both `include_tasks: tasks/homebrew_packages.yaml` and `tasks/asdf_tool_versions.yaml`. Only the OS-specific halves differ (casks/colima/fonts/rosetta on macOS; apt-repos/docker-ce/linuxbrew on Debian). The Oh My Zsh install block is the *same intent* with a trivially-unifiable implementation.
- `inventory.ini` is vestigial for daily use — every function passes `--inventory 127.0.0.1,` and runs locally. Only `nvidia_setup.yaml` uses the `nr200p` SSH host. So it stays solely for that one manual play.
- The shared-include pattern (`tasks/*.yaml` + `vars/*.yml`, per ADR-0001/0002) is proven and can absorb the OS split and the symlink engine.

### Target structure

Introduce a single **`ansible/provision.yaml`** (`hosts: localhost`, `connection: local`, `gather_facts: yes`) that fans out — replacing the shell-side `uname` branch and the separate base playbooks:

```
provision.yaml
  vars_files: vars/homebrew_packages.yml
  tasks:
    - include_tasks: tasks/oh_my_zsh.yaml            # unified (get_url on both OSes)
    - include_tasks: tasks/macos.yaml   when: ansible_os_family == 'Darwin'
    - include_tasks: tasks/debian.yaml  when: ansible_os_family == 'Debian'
    - include_tasks: tasks/homebrew_packages.yaml    # shared (brew or linuxbrew)
    - include_tasks: tasks/asdf_tool_versions.yaml   # shared
    - include_tasks: tasks/link_dotfiles.yaml
        vars: { links: "{{ personal_dotfile_links }}" }
    - include_tasks: tasks/link_dotfiles.yaml        # work overlay, only on work laptop
        vars: { links: "{{ workday_dotfile_links }}" }
      when: dotfiles_wd_present | bool
```

Concretely:
1. **Split the OS-specific halves out** of the two `base_setup*` playbooks into `tasks/macos.yaml` (casks, colima, localsend tap, fonts→`/Library/Fonts`, rosetta) and `tasks/debian.yaml` (apt keyrings/repos, apt packages, docker-ce, linuxbrew, reboot-if-needed, autoremove). Move the shared OMZ install into `tasks/oh_my_zsh.yaml`. The old `base_setup.yaml` / `base_setup_debian.yaml` become thin or are deleted once `provision.yaml` supersedes them.
2. **One symlink engine** — `tasks/link_dotfiles.yaml`: the generic "remove-then-link" loop from `git_setup.yaml`, driven by a `links` var. Feed it `personal_dotfile_links` (from `git_setup.yaml`'s existing `dotfile_links`) and, on the work laptop, `workday_dotfile_links` (replacing the hand-written static loop in workday `setup.yaml`). OS-varying dests (ghostty/lazygit `~/Library/Application Support/...`, p10k `gitstatusd-darwin-arm64`) become OS-driven vars.
3. **One `tasks/link_tree.yaml`** parameterised by `src_root` + `dest_root` to replace the **three near-identical** find→mkdir→`regex_replace`→symlink blocks in workday `setup.yaml` (ai/skills, howdah/skills, howdah/rules) and the oh-my-zsh/tmuxinator find loops.
4. **Guard external-repo assumptions** (`~/Code/workday/tools/environments-ssh-config`, `~/Code/workday/mia/ai/howdah/...`) with `stat` + `when` so a fresh laptop without those checkouts skips rather than fails.
5. **Wire in the orphans**: fold `tldr_setup.yaml` into the personal link step (or drop it if unused); either call `claude.yaml` from `provision.yaml` or merge its dynamic prune-aware link logic into `tasks/link_dotfiles.yaml` (it is the most robust pattern — reconciles/prunes stale links). Keep `nvidia_setup.yaml` standalone.
6. **Variabilise the workday checkout root** — `setup.yaml`'s hardcoded `~/Code/workday/eoin-farrell/dotfiles/...` becomes `{{ dotfiles_wd }}`, so a relocated checkout still links correctly. This subsumes the earlier Phase-1 note about `setup.yaml`.
7. **Collapse `updateMachine`** (`zsh/functions.sh`): replace the `uname` branch + separate `base_setup`/`git_setup` calls with a single `ansible-playbook provision.yaml` run. The work overlay runs inside the same playbook via the `dotfiles_wd_present` guard, so `getLatestPackagesWD` keeps only its repo-pull/CLI-build duties (drop its `setup.yaml` call, or leave it for standalone use).
8. **Fix the copy-paste comment headers** in `git_setup.yaml` / `claude.yaml` / workday `setup.yaml` (all mis-name the playbook).

### Sequencing / risk

This is the largest phase and touches provisioning, so stage it:
- **3a** — extract shared includes (`tasks/macos.yaml`, `tasks/debian.yaml`, `tasks/oh_my_zsh.yaml`) and add `provision.yaml` that reproduces today's behaviour; keep old playbooks until proven. Verify with `--check --diff` on this Mac (empty diff = equivalent).
- **3b** — introduce `tasks/link_dotfiles.yaml` + `tasks/link_tree.yaml`, migrate personal `git_setup` links, then the workday `setup.yaml` links (variabilised). `--check --diff` must show identical symlink targets.
- **3c** — switch `updateMachine` to the single `provision.yaml` call; run for real on this machine and confirm symlinks/packages unchanged. Retire superseded playbooks.
- Debian path (`tasks/debian.yaml`) can only be fully verified on a Debian box (`nr200p` or `t480`) — until then rely on `--check` and keep `base_setup_debian.yaml` as a fallback.

## Phase 4 — Consistency: config-file naming & shared shell files

- **`zsh/startup/validation.sh` exists in both repos with different content** (personal checks tmux/kubectx; work checks okta2aws/sso CLIs). Rename the work one to `zsh/startup/workday-validation.sh` (it is already sourced explicitly from work `init.sh:22`) so the two repos don't collide on an identically-named file with divergent behaviour. Also soften its hard `return 1` (work `validation.sh` can currently abort shell init if a CLI is missing) to a warning.
- Standardise config-file dot-prefix convention (personal repo mixes `.gitconfig`/`.tigrc` with plain `zshrc`/`config`). Pick one rule — *dot-prefix only when the symlink target in `$HOME` is dotted* is the least churn — and document it in `docs/adr/`. This is a documentation/convention decision, not a mass rename, unless you want the rename.

## Phase 5 — Consistency: documentation parity (work repo)

The work repo has **no** `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `docs/adr/`, or `docs/agents/`; personal has all of them.

- Add a work-repo `CLAUDE.md` (+ `AGENTS.md` symlink, matching personal) that states: this is a satellite of `$DOTFILES`, is sourced by it, depends on personal for sops/update helpers, and points at the same agent-skill docs.
- Add `docs/adr/` to the work repo and record the key decisions this overhaul makes (path-variabilisation, single `DOTFILES_WD` name, satellite relationship). Reuse the personal repo's ADR format (`docs/adr/0001-*`).
- **Create the missing `CONTEXT.md` in the personal repo** — it is referenced by `CLAUDE.md` and `docs/agents/domain.md` but does not exist. Write it to describe the two-repo parent/satellite architecture (this plan's Context section is a good seed).
- Cross-link: personal `CONTEXT.md` ↔ work `CLAUDE.md` so the relationship is discoverable from either side.

## Phase 6 (optional, low-priority) — hygiene the consistency work exposes

Not the focus areas, but cheap and reduces confusion while doing the above:

- Remove tracked junk: work `kubeswitch/switch.alias.bak`, stray `gradle/.!60425!gradle.properties` (Finder copy fragment), personal committed `.DS_Store`, empty `useful-commands.sh`.
- Note (do **not** silently change) the `gradle/gradle.properties` secret flow: it is gitignored and rewritten each shell via `sed` from `$ARTIFACTORY_*` env vars (work `init.sh:16-17`), while npm/terraform/jira use sops. Flagged for a future decision, out of scope here.

---

## Critical files

Work repo (`$DOTFILES_WD`): `envStart/base.sh`, `ansible/setup.yaml`, `zsh/init.sh`, `zsh/startup/validation.sh` (→ rename), `zsh/workday-functions.sh`, `kubeswitch/switch-config.yaml`, `aws/config`.
Personal repo (`$DOTFILES`): `zsh/startup/init.sh` (env vars, the source seam at :30-31), `ansible/git_setup.yaml` (the `dotfile_links` pattern to mirror), `ansible/tasks/` (include pattern to mirror), `docs/adr/`, `CLAUDE.md`, and the new `CONTEXT.md`.

## Verification

Portability and consistency are shell-behaviour changes, so verify by exercising the shell and provisioning end-to-end:

1. **No stray absolute paths:** `grep -rn '/Users/eoin.farrell' $DOTFILES_WD` returns only the documented, non-expandable exceptions.
2. **No stale env-var names:** `grep -rn 'WDDOTFILES\|WdDOTFILESD' $DOTFILES $DOTFILES_WD` returns nothing.
3. **Shell still loads clean:** open a fresh login shell (`zsh -l -i -c 'echo $DOTFILES_WD; echo $ENV_START_DIR'`) — both resolve correctly, no errors from validation.
4. **Ansible dry-run:** `ansible-playbook --check --diff $DOTFILES_WD/ansible/setup.yaml` and `ansible-playbook --check --diff $DOTFILES/ansible/git_setup.yaml` — symlinks resolve to the same targets as before (diff should be empty on this machine, proving the variabilised paths are equivalent).
5. **Real apply on this machine:** run both playbooks for real; confirm symlinks under `~/.kube`, `~/.aws`, `~/.config/tmuxinator`, `~/.oh-my-zsh/custom` still point where they did (`ls -la`).
6. **Portability spot-check:** temporarily set `DOTFILES_WD` to a copy in a different path and source `envStart/base.sh` — `ENV_START_DIR` follows it (proves no residual hardcoding).
7. **Docs:** confirm `CONTEXT.md` exists and `CLAUDE.md`/`domain.md` references resolve; work-repo `CLAUDE.md` + `AGENTS.md` symlink present.

Each phase is committed separately (on a branch, per the personal repo's convention) so any regression is bisectable.
