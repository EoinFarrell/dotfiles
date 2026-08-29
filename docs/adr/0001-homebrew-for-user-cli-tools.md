# 1. Homebrew for user/CLI tools, apt for OS-level packages

## Status

Accepted

## Context

The provisioners for macOS (`ansible/base_setup.yaml`) and Debian
(`ansible/base_setup_debian.yaml`) installed the same class of tool
(user/CLI packages like `git`, `jq`, `lsd`, `tig`, `tmux`, `zsh`) through
two different package managers — Homebrew on macOS, apt on Debian — with
no shared list. Adding a new cross-platform tool meant editing both
playbooks and re-deciding which package manager to use each time. See
`docs/agents/package-install-standardisation-research.md` for the full
comparison of candidates (Homebrew everywhere, per-OS wrapper scripts,
Nix/devbox, status quo).

The Debian box (`nr200p`) already runs Linuxbrew successfully
(`base_setup_debian.yaml` installed `tldr` and `helix` through it), so
extending Homebrew to cover the rest of the user/CLI tools was a small
step rather than a new dependency.

## Decision

- **User/CLI tools** (editors, linters, `kubectl`-style clients, shell
  utilities, etc.) are installed via Homebrew on both macOS and Debian
  (Linuxbrew). The single source of truth is `ansible/vars/homebrew_packages.yml`
  — that's the one place to add a new tool, consumed by both playbooks
  through the shared `ansible/tasks/homebrew_packages.yaml` task file.
- **OS-level packages** — daemons, kernel modules, drivers, and anything
  that needs `apt`/`systemd` integration (Docker Engine, Tailscale,
  Terraform, NVIDIA, `build-essential`, `nfs-common`,
  `software-properties-common`) — stay on apt in
  `ansible/base_setup_debian.yaml`. Homebrew's own Linux system
  dependencies (`build-essential`, `procps`, `curl`, `file`, `git`) are
  also installed via apt, since Homebrew needs them before it can run.
- **GUI apps** (casks) stay macOS-only in `ansible/base_setup.yaml`,
  since Homebrew casks have no Linux equivalent. The same goes for
  formulae that are only meaningful on macOS, like `colima` (a Docker
  Desktop replacement) and `localsend` — Debian already runs Docker
  Engine natively via apt, so these stay in a macOS-only Homebrew task
  instead of the shared list.

## Consequences

- A new cross-platform CLI tool is a one-line addition to
  `ansible/vars/homebrew_packages.yml`, with no playbook edits required
  on either OS. This is what makes adding the Pi coding-agent CLI
  (issue #11) straightforward: append it to the shared list (or add an
  `npm install -g` task next to the shared asdf Node.js setup if Pi isn't
  published as a formula).
- `git` is installed via both apt (to bootstrap Homebrew itself on
  Debian) and the shared Homebrew list (for the managed version used
  day-to-day). This intentional duplication is called out in a comment
  in `base_setup_debian.yaml`.
- Some formulae in the shared list build from source on Linux rather
  than installing a prebuilt bottle (e.g. `ansible`, `awscli`, `tig`,
  `tmux`, `watch` at the time of writing). This trades a slower first
  install for a single cross-platform package list; see the research doc
  for the bottle-availability table.
- Terraform stays on apt via HashiCorp's repo rather than moving to
  Homebrew, since Terraform was pulled from `homebrew-core` and now
  requires the `hashicorp/tap` formula — left as a follow-up if that tap
  proves reliable enough to replace the apt repo.
