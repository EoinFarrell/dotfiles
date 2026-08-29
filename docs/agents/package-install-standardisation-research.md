# Standardise package installation across macOS and Debian provisioners

Goal: pick one obvious place to add a new user/CLI tool, reduce duplication between `ansible/base_setup.yaml` and `ansible/base_setup_debian.yaml`, and make it easy to decide when apt, Homebrew, or something else is appropriate.

## Quick comparison

| Candidate | One place for CLI tools | Cross-platform list | OS-level packages (Docker Engine, Tailscale daemon, kernel/NVIDIA) | Ansible module support | Bootstrap complexity | Idempotency | Disk / speed | Fit for Pi harness (#11) |
|---|---|---|---|---|---|---|---|---|
| **1. Homebrew everywhere** | `Brewfile` or single `community.general.homebrew` loop | Yes — Homebrew supports macOS, Linux, WSL | Keep apt for daemons/kernel; Homebrew for user/CLI | `homebrew`, `homebrew_cask`, `homebrew_tap` | Low — `setup.sh` already installs Homebrew; Debian box already uses Linuxbrew | High — `brew`/`brew bundle` are idempotent | Bottles are fast; source builds slow. Linuxbrew prefix avoids system dirs | Pi CLI via `npm` (node installable via brew) or a new formula; fits the shared tool list |
| **2. Best-tool wrapper scripts** | `bin/install-package` abstracting `brew`/`apt` | Hidden behind wrapper, but lists still split | Wrapper can delegate to apt | Custom script via `command`/`shell` | Medium — write + maintain wrapper and inventory mappings | Depends on wrapper implementation | Native speed, but wrapper adds indirection | Same as status quo underneath |
| **3. Nix / devbox** | `devbox.json` or `flake.nix` | Yes — identical Nix packages on both OSes | NixOS modules/flakes can manage daemons; on macOS/Debian non-NixOS it is awkward | No official Ansible Nix module; use `command`/`shell` | High — introduce Nix language, flakes, store volume, substituters | Very high — pure, reproducible, lock file | Large `/nix/store`, slow first install, fast after | Strong fit once learned; Pi CLI could be a flake input |
| **4. Status quo** | Two playbooks + shell bootstraps | No — macOS in `base_setup.yaml`, Debian in `base_setup_debian.yaml` | Apt on Debian, casks/Homebrew on macOS | `homebrew`, `apt` | None — already works | High per module, but duplicated logic | Native speed | Same duplication problem |

## 1. Current state

The repo currently provisions two machines differently:

- **macOS**: bootstrap in `setup.sh` installs Homebrew to `/opt/homebrew`, then installs Ansible via Homebrew and runs `ansible/base_setup.yaml`. [`setup.sh` lines 1–58](../../setup.sh#L1-L58).
- **Debian (`nr200p`)**: bootstrap in `temp.sh` adds the Ansible PPA and installs `gh` and VS Code via apt. [`temp.sh` lines 1–31](../../temp.sh#L1-L31). Playbook `ansible/base_setup_debian.yaml` installs Docker, Tailscale, Terraform, and other base packages via apt, then installs Linuxbrew to `/home/linuxbrew/.linuxbrew` and uses it for `tldr` and `helix`. [`ansible/base_setup_debian.yaml` lines 115–252](../../ansible/base_setup_debian.yaml#L115-L252).

This means a new CLI tool must be added in up to three places (`base_setup.yaml`, `base_setup_debian.yaml`, possibly `temp.sh`) and the choice of backend is not explicit.

## 2. Candidate 1: Homebrew everywhere

### 2.1 Homebrew on Linux

Homebrew supports Linux and WSL. The supported install prefix on Linux is `/home/linuxbrew/.linuxbrew`, which is already what `base_setup_debian.yaml` uses. [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux). The installer uses `sudo` once to create that prefix; after install Homebrew does **not** use `sudo`. Tier 1 Linux support requires Ubuntu in standard support, glibc ≥ 2.39, default prefix, and x86_64/ARM64. Older glibc is Tier 2 and Homebrew installs its own `glibc` and `gcc` automatically. [Homebrew Support Tiers](https://docs.brew.sh/Support-Tiers).

System dependencies on Debian/Ubuntu are `build-essential procps curl file git` — all already installed by `base_setup_debian.yaml` except `procps` and `file`. [Homebrew on Linux requirements](https://docs.brew.sh/Homebrew-on-Linux#requirements).

### 2.2 Package availability

Most user/CLI tools in the macOS playbook are available as Homebrew formulae on both macOS and Linux:

| Tool | Homebrew formula | Linux bottle | Notes |
|---|---|---|---|
| `ansible` | `ansible` | No (macOS only bottle at time of check) | Usually installed via pip or system package to bootstrap |
| `awscli` | `awscli` | No | Python-based; may build from source on Linux |
| `bat` | `bat` | Yes | |
| `colima` | `colima` | Yes | Containers on macOS + Linux |
| `coreutils` | `coreutils` | Yes | |
| `docker-compose` | `docker-compose` | Yes | |
| `doggo` | `doggo` | Yes | |
| `gh` | `gh` | Yes | |
| `git` | `git` | Yes | |
| `guile` | `guile` | Yes | |
| `helm` | `helm` | Yes | |
| `hstr` | `hstr` | Yes | |
| `hugo` | `hugo` | Yes | |
| `jq` | `jq` | No | Often already on Debian base images |
| `kubectl` | `kubernetes-cli` | Yes | Alias `kubectl` resolves in CLI; API returns `kubernetes-cli` |
| `kubectx` | `kubectx` | Yes | |
| `kubecolor` | `kubecolor` | Yes | |
| `lazydocker` | `lazydocker` | Yes | |
| `lazygit` | `lazygit` | Yes | |
| `lsd` | `lsd` | Yes | |
| `mdcat` | `mdcat` | Yes | |
| `mysql` | `mysql` | Yes | |
| `openssl@3` | `openssl@3` | Yes | |
| `prettier` | `prettier` | Yes | |
| `protobuf` | `protobuf` | Yes | |
| `rsync` | `rsync` | No | macOS only bottle at time of check |
| `superfile` | `superfile` | Yes | |
| `tig` | `tig` | No | macOS only bottle at time of check |
| `tealdeer` (`tldr`) | `tealdeer` | Yes | |
| `tmux` | `tmux` | No | macOS only bottle at time of check |
| `tmuxinator` | `tmuxinator` | Yes | |
| `tree` | `tree` | Yes | |
| `watch` | `watch` | No | macOS only bottle at time of check |
| `wget2` | `wget2` | Yes | |
| `zsh` | `zsh` | Yes | |
| `kubefwd` | `txn2/tap/kubefwd` | Yes | Third-party tap |
| `localsend` | `localsend` (cask) | N/A | Cask is macOS-only; Linux uses Flatpak or appimage |

Availability verified against the [Homebrew JSON API](https://formulae.brew.sh/docs/api/) (`https://formulae.brew.sh/api/formula/<name>.json` and `/api/cask/<name>.json`) on 2026-08-29.

Casks are macOS-only by design (they install `.app` bundles or signed binaries). [Homebrew Formula Cookbook — terminology](https://docs.brew.sh/Formula-Cookbook#homebrew-terminology). Therefore GUI apps stay in the macOS playbook or a macOS-only Brewfile block.

### 2.3 Declarative option: Brewfile

Homebrew Bundle (`brew bundle`) reads a `Brewfile` and supports `brew`, `cask`, `tap`, `mas`, and more. It is idempotent and cross-platform for formulae. [Homebrew Bundle docs](https://docs.brew.sh/Brew-Bundle-and-Brewfile). It can gate entries by OS:

```ruby
brew "git"
brew "bat"
brew "zsh"
brew "glibc" if OS.linux?
cask "visual-studio-code" if OS.mac?
```

`brew bundle` does **not** pin versions and has no lock file; it is a rolling-release manager. [Homebrew Bundle versions note](https://docs.brew.sh/Brew-Bundle-and-Brewfile#versions).

### 2.4 Ansible integration

- `community.general.homebrew` installs/removes formulae; default `path` already includes `/opt/homebrew/bin` and `/home/linuxbrew/.linuxbrew/bin`. [Ansible homebrew module](https://docs.ansible.com/ansible/latest/collections/community/general/homebrew_module.html).
- `community.general.homebrew_cask` manages casks; macOS-only. [Ansible homebrew_cask module](https://docs.ansible.com/ansible/latest/collections/community/general/homebrew_cask_module.html).
- `community.general.homebrew_tap` manages taps. [Ansible homebrew_tap module](https://docs.ansible.com/ansible/latest/collections/community/general/homebrew_tap_module.html).

A single `homebrew` task with a looped list works, but passing the list to the `name` parameter is more efficient. [Ansible homebrew module notes](https://docs.ansible.com/ansible/latest/collections/community/general/homebrew_module.html#notes).

### 2.5 What stays on apt

Homebrew is a user-space package manager. OS-level concerns still need apt:

- Docker Engine (`docker-ce`, `containerd.io`, buildx/compose plugins) — the daemon needs systemd and kernel support. Docker Desktop on macOS is a cask (`docker-desktop`).
- Tailscale daemon — Tailscale packages its own apt repo for Linux; the macOS Tailscale app is a cask.
- NVIDIA drivers/Steam — hardware-specific Debian packages.
- Kernel headers, `build-essential`, `nfs-common`, `software-properties-common`.

This is consistent with the issue’s framing: “Use `brew install` on macOS and Debian alike for user/CLI tools; only fall back to apt for OS-level packages.”

### 2.6 Pi harness fit

Issue #11 installs the Pi coding-agent CLI. Pi is distributed as an npm package (`@earendil-works/pi-coding-agent`) or via `pi install`. The shared setup should install Node.js via the asdf `nodejs` plugin (or via Homebrew `node` as a short-term fallback) and then run `npm install -g @earendil-works/pi-coding-agent`. If Pi later publishes a Homebrew formula or tap, it drops into the same list as any other CLI tool.

## 3. Candidate 2: Best-tool-for-the-job per OS with wrapper scripts

### 3.1 Idea

Keep apt on Debian and Homebrew on macOS, but add `bin/install-package` so playbooks read:

```yaml
- name: Install bat
  ansible.builtin.command: "bin/install-package bat"
```

### 3.2 Trade-offs

- **Pro:** Uses the native, fastest backend on each OS.
- **Con:** Still maintains two package lists (one in the wrapper mapping, one per OS). The wrapper itself becomes a new abstraction that must be reasoned about and tested.
- **Con:** Ansible idempotency is weaker — `command`/`shell` modules do not natively report whether a package changed.
- **Con:** Adds a custom script that every future contributor must understand before adding a package.

This is a pragmatic compromise but does not fully meet the “one obvious place” goal; it just hides the split.

## 4. Candidate 3: Nix / devbox

### 4.1 Nix

Nix is a purely functional package manager. It supports multi-user installs on macOS and Linux with a daemon, and single-user installs on Linux without systemd. [Nix install docs](https://nixos.org/manual/nix/stable/installation/installing-binary.html). Packages are declared in Nix expressions or flakes. Flakes provide lock files (`flake.lock`) for reproducibility but are still marked experimental. [Nix flake docs](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html). Nixpkgs contains over 140,000 packages. [Nixpkgs repo](https://github.com/NixOS/nixpkgs).

### 4.2 devbox

devbox is a CLI that wraps Nix for project and global environments. Global packages live in a `devbox.json` under the home directory and can be synced across machines. [devbox global docs](https://www.jetify.com/docs/devbox/devbox-global/). A `devbox.json` lists Nix packages and supports platform filtering:

```json
{
  "packages": {
    "git": "latest",
    "docker-compose": "latest",
    "busybox": { "version": "latest", "platforms": ["x86_64-linux", "aarch64-linux"] }
  }
}
```

[devbox.json reference](https://www.jetify.com/docs/devbox/configuration/). The install script is `curl -fsSL https://get.jetify.com/devbox | bash`; devbox can install Nix automatically. [devbox install docs](https://www.jetify.com/docs/devbox/installing-devbox/).

### 4.3 Ansible integration

There is **no** official `community.general.nix` module. Attempting to fetch `https://docs.ansible.com/ansible/latest/collections/community/general/nix_module.html` returns 404. Nix/devbox would be driven from Ansible via `ansible.builtin.command` or `ansible.builtin.shell`:

```yaml
- ansible.builtin.command: devbox global add {{ item }}
  loop: "{{ devbox_packages }}"
```

This loses the native idempotency and change detection that `homebrew` and `apt` modules provide.

### 4.4 Trade-offs

- **Pro:** Identical package versions across macOS and Debian; lock file for reproducibility.
- **Pro:** Strong fit for CI and for issue #11 if Pi is packaged as a Nix flake or devbox input.
- **Con:** Steep learning curve — Nix language, flakes, `/nix/store` volume, substituters, GC roots.
- **Con:** macOS install creates a separate APFS volume and LaunchDaemon; Nix on macOS has had friction with macOS upgrades. [Nix macOS install notes](https://nixos.org/manual/nix/stable/installation/installing-binary.html#macos-installation).
- **Con:** No native Ansible module; idempotency must be reimplemented.
- **Con:** The repo already has a working Homebrew-on-Linux setup; switching everything to Nix is a large migration.

## 5. Candidate 4: Status quo

Keep adding packages to `base_setup.yaml` for macOS and `base_setup_debian.yaml` for Debian. This is the current approach and works, but it directly contradicts the issue goals: there is no single obvious place to add a tool, duplication is high, and the boundary between apt and brew is implicit.

## 6. Recommendation

**Adopt Candidate 1: Homebrew everywhere, with apt reserved for OS-level packages.**

### Rationale

1. **Aligns with current trajectory.** Linuxbrew is already installed and used successfully on the Debian box (`base_setup_debian.yaml` lines 219–252). The macOS playbook is already Homebrew-native. Extending Linuxbrew to cover all user/CLI tools is a small step, not a rewrite.
2. **One obvious place.** A shared `Brewfile` (or a single shared package list consumed by `community.general.homebrew`) becomes the canonical location for new CLI tools. The rule “user tools go in Homebrew; OS daemons and kernel stuff stay in apt” is easy to explain and enforce.
3. **Minimal duplication.** The overlapping packages (`git`, `gh`, `jq`, `lsd`, `tig`, `tmux`, `wget2`, `zsh`, `tealdeer`/`tldr`, `helix`) move into one list. macOS-specific casks and Debian-specific daemon repos stay in OS-specific playbooks.
4. **Ansible-native idempotency.** `community.general.homebrew` and `homebrew_cask` are well-supported, check-mode capable, and already used in the repo.
5. **Pi harness fit (#11).** Node.js is installed via the asdf `nodejs` plugin, and the Pi CLI install becomes a small extra task rather than a new backend.

### Suggested implementation outline

1. Create `ansible/group_vars/all/homebrew_packages.yml` (or a repo-root `Brewfile`) with the shared user/CLI list.
2. Refactor `ansible/base_setup.yaml` to consume that list for formulae and keep only macOS casks and Rosetta.
3. Refactor `ansible/base_setup_debian.yaml` to move the shared Debian packages from apt into the Homebrew list, leaving only Docker, Tailscale, Terraform apt repo, `build-essential`, `nfs-common`, and similar OS-level packages in apt.
4. Document the boundary in `README.md` and add a one-line comment at the top of the shared list: “User/CLI tools only — OS daemons and kernel packages stay in apt.”

### What not to do

- Do **not** try to install Docker Engine or Tailscale daemon via Homebrew on Linux — use apt for those.
- Do **not** move GUI casks to the shared list — casks are macOS-only.

---

## Sources

- Homebrew on Linux: <https://docs.brew.sh/Homebrew-on-Linux>
- Homebrew Support Tiers: <https://docs.brew.sh/Support-Tiers>
- Homebrew Formulae / JSON API: <https://formulae.brew.sh/>
- Homebrew Bundle / Brewfile: <https://docs.brew.sh/Brew-Bundle-and-Brewfile>
- Homebrew Formula Cookbook terminology: <https://docs.brew.sh/Formula-Cookbook#homebrew-terminology>
- HashiCorp Homebrew Tap: <https://github.com/hashicorp/homebrew-tap>
- Ansible `community.general.homebrew` module: <https://docs.ansible.com/ansible/latest/collections/community/general/homebrew_module.html>
- Ansible `community.general.homebrew_cask` module: <https://docs.ansible.com/ansible/latest/collections/community/general/homebrew_cask_module.html>
- Ansible `community.general.homebrew_tap` module: <https://docs.ansible.com/ansible/latest/collections/community/general/homebrew_tap_module.html>
- Ansible `ansible.builtin.apt` module: <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html>
- Ansible conditionals / facts: <https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_conditionals.html>
- Nix binary install docs: <https://nixos.org/manual/nix/stable/installation/installing-binary.html>
- Nix flakes docs: <https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html>
- Nixpkgs repo: <https://github.com/NixOS/nixpkgs>
- devbox install docs: <https://www.jetify.com/docs/devbox/installing-devbox/>
- devbox global docs: <https://www.jetify.com/docs/devbox/devbox-global/>
- devbox.json reference: <https://www.jetify.com/docs/devbox/configuration/>
- Repo `setup.sh`: `setup.sh` (macOS bootstrap: Homebrew, Ansible)
- Repo `temp.sh`: `temp.sh` (Debian/Ubuntu bootstrap: Ansible PPA, gh, VS Code)
- Repo `ansible/base_setup.yaml`: macOS Homebrew playbook (incl. asdf + Node.js setup)
- Repo `ansible/base_setup_debian.yaml`: Debian apt + Linuxbrew playbook
- Repo `ansible/git_setup.yaml`: dotfile symlink playbook (links `.asdfrc`, ghostty config, etc.)
- Repo `zsh/functions.sh`: shell functions (`getLatestPackages`, `rubyBuildEnv`)
- Repo `zsh/startup/random.sh`: shell aliases/env
- Repo `zsh/startup/autocomplete.sh`: asdf completion setup
- Repo `zsh/oh-my-zsh/powerlevel10k.zsh`: prompt config
- Repo `git/.gitconfig`: Git config (workday includeIf for `~/.asdf/`)
- Repo `git/.gitignore`: ignores `.tool-versions`
- Repo `brew/zd/Brewfile`: work Mac Brewfile
- Repo `brew/vmw/casks`: macOS cask list
- Repo `README.md`: project overview and bootstrap instructions
- GitHub issue #11 (Pi agent harness): `gh issue view 11`
- mise-en-place (asdf-compatible replacement): <https://mise.jdx.dev/>
