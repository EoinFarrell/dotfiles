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
from this repo to `~/.asdfrc` / `~/.tool-versions`, and a task run from
both `base_setup.yaml` (macOS) and `base_setup_debian.yaml` (Debian)
installed the asdf `nodejs` plugin and the version pinned in
`asdf/.tool-versions`. Node.js was already on asdf; fixing the panic in
`go-scripts/script.go` (issue #5) needed a Go toolchain to build and
test, which surfaced that there was no documented rule for where a
*second* language runtime should live — Homebrew has a `go` formula
too, and installing it directly was the default reach until corrected.

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
  `nodejs 22.14.0` line. No playbook or task-file edit is required: both
  `base_setup.yaml` and `base_setup_debian.yaml` run the shared
  `ansible/tasks/asdf_tool_versions.yaml`, which reads
  `asdf/.tool-versions` line by line and runs `asdf plugin add` /
  `asdf install` for each pinned runtime. This replaced the earlier
  per-runtime `tasks/asdf_nodejs.yaml`, which hard-coded the Node.js
  version and would have needed a near-identical `asdf_golang.yaml`
  copy-pasted alongside it.
- The generalised task deliberately skips `asdf global`/`asdf set -u`:
  that step would just write the same plugin/version pairs into
  `~/.tool-versions`, which `git_setup.yaml` already symlinks to this
  same `asdf/.tool-versions` file, so asdf resolves the pinned versions
  as the global default as soon as they're installed. It's also no
  longer available as `asdf global` on current asdf (0.18+ renamed it to
  `asdf set -u`), which the old per-runtime task would have silently
  hit on a fresh install.
- `asdf/.asdfrc` (`legacy_version_file = no`) means a runtime won't
  fall back to reading `.nvmrc`/`go.mod`-style version files — the
  pinned version always comes from `.tool-versions`.
