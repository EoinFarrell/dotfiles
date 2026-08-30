# 2. asdf for language runtime versions

## Status

Accepted

## Context

[[0001-homebrew-for-user-cli-tools]] draws the line for user/CLI tools
(editors, linters, shell utilities) at Homebrew on both macOS and Debian.
Language runtimes are a different class of dependency: projects pin to a
specific version (a `package.json` engines field, a `go.mod` toolchain
directive), and Homebrew only ever tracks one installed version at a time
system-wide, with no per-project switching.

`git_setup.yaml` already symlinks `asdf/.asdfrc` and `asdf/.tool-versions`
from this repo to `~/.asdfrc` / `~/.tool-versions`, and
`ansible/tasks/asdf_nodejs.yaml` installs the asdf `nodejs` plugin and the
version pinned in `asdf/.tool-versions`, run from both
`base_setup.yaml` (macOS) and `base_setup_debian.yaml` (Debian). Node.js
was already on asdf; fixing the panic in `go-scripts/script.go` (issue #5)
needed a Go toolchain to build and test, which surfaced that there was no
documented rule for where a *second* language runtime should live —
Homebrew has a `go` formula too, and installing it directly was the
default reach until corrected.

## Decision

- **Language runtimes** (Node.js, Go, and any future interpreter/compiler
  a project in this repo needs) are installed and version-pinned via
  asdf, not Homebrew. `asdf/.tool-versions` is the single source of
  truth for which version is active — that's the one file to edit to add
  or bump a runtime, consumed via the `~/.tool-versions` symlink set up
  in `git_setup.yaml`.
- **User/CLI tools** stay on Homebrew per [[0001-homebrew-for-user-cli-tools]].
  The boundary: if a tool is invoked as `<tool> --version` to run a
  command, it's a CLI tool (Homebrew); if a project's source depends on
  it and pins a specific version to build or run, it's a language
  runtime (asdf).

## Consequences

- Adding a new language runtime is a one-line addition to
  `asdf/.tool-versions` (e.g. `golang 1.27.0`), matching the existing
  `nodejs 22.14.0` line.
- That line alone doesn't provision the runtime on a fresh machine: only
  Node.js has an ansible task (`tasks/asdf_nodejs.yaml`, run from both
  playbooks) that runs `asdf plugin add` and `asdf install` for the
  pinned version. Go was added to `asdf/.tool-versions` without an
  equivalent `tasks/asdf_golang.yaml` — left as a follow-up, either a
  second per-runtime task file on the same pattern or a generalised task
  that loops over every line in `asdf/.tool-versions`.
- `asdf/.asdfrc` (`legacy_version_file = no`) means a runtime won't
  fall back to reading `.nvmrc`/`go.mod`-style version files — the
  pinned version always comes from `.tool-versions`.
