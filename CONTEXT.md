# Context: dotfiles

## Glossary

**Root repo** — `~/Code/personal/dotfiles` (`$DOTFILES`). Bootstraps standalone: its `zsh/startup/init.sh` sets up the shell environment, exports `$DOTFILES_WD`, and sources the satellite repo if present. Defines shared machinery (sops helpers, `getLatestFromGit`, symlink conventions, docs format) that the satellite reuses rather than duplicates. Used on multiple personal machines: a macOS laptop, and two Debian boxes — `nr200p` (desktop) and `t480` (laptop).

**Satellite repo** — `~/Code/workday/eoin-farrell/dotfiles` (`$DOTFILES_WD`). Work-specific overlay, used only on the work laptop. Cannot bootstrap on its own — it relies on being sourced by the root repo's `init.sh`, and calls back into root-defined helpers (`_sops_decrypt_if_changed`, `getLatestFromGit`, `sops-watch.sh`). A satellite depends on its root; a root never depends on a satellite.

**`$DOTFILES_WD`** — the single canonical env var naming the satellite repo's path. (Historical aliases `WDDOTFILES` / `WdDOTFILESD` have been removed — one name per concept.)
