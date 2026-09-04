#!/bin/bash

# Each _update* step guards on the binary it needs and reports why it
# skipped, so a missing tool on this machine fails loud instead of
# silently dropping unrelated steps (e.g. brew upgrades used to be
# gated on `switch -v kubectl`, which had nothing to do with brew).

_updateAsdf() {
    if [ -x "$HOME/.asdf/bin/asdf" ]; then
        "$HOME/.asdf/bin/asdf" update
    else
        echo "asdf not found, skipping asdf update"
    fi
}

_updateTldr() {
    if command -v tldr >/dev/null 2>&1; then
        tldr --update
    else
        echo "tldr not found, skipping tldr update"
    fi
}

_updateTmuxinator() {
    if command -v gem >/dev/null 2>&1; then
        gem update tmuxinator
    else
        echo "gem not found, skipping tmuxinator update"
    fi
}

_updatePluginRepos() {
    local pluginsd=$ZSH_CUSTOM/plugins

    getLatestFromGit "$pluginsd/git-open" "https://github.com/paulirish/git-open.git"
    getLatestFromGit "$pluginsd/zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    getLatestFromGit "$pluginsd/zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
    getLatestFromGit "$pluginsd/zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git"

    local completionsDir=$pluginsd/zsh-completions
    getLatestFromGit "$completionsDir" "https://github.com/zsh-users/zsh-completions"
    fpath+=$completionsDir/src

    getLatestFromGit "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" "https://github.com/romkatv/powerlevel10k.git"
}

# Regenerated file here is loaded via the kubectl-autocomplete oh-my-zsh
# plugin, added to `plugins=(...)` in zsh/zshrc and sourced from there.
_updateKubectlCompletion() {
    if command -v kubectl >/dev/null 2>&1; then
        kubectl completion zsh > ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete/kubectl-autocomplete.plugin.zsh
    else
        echo "kubectl not found, skipping kubectl completion regen"
    fi
}

# Regenerated file here is loaded via the switch-autocomplete oh-my-zsh
# plugin, added to `plugins=(...)` in zsh/zshrc and sourced from there.
_updateSwitchCompletion() {
    if command -v switch >/dev/null 2>&1; then
        switch completion zsh > ~/.oh-my-zsh/custom/plugins/switch-autocomplete/switch-autocomplete.plugin.zsh
    else
        echo "switch not found, skipping switch completion regen"
    fi
}

_updateBrew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "brew not found, skipping Homebrew upgrade"
        return
    fi

    if ! command -v go >/dev/null 2>&1; then
        echo "go not found, skipping Homebrew upgrade (needed to filter outdated packages)"
        return
    fi

    (cd "$DOTFILES/go-scripts" && brew outdated --json | go run ./script.go | xargs brew upgrade)

    echo "----Brew Outdated----"
    brew outdated
    echo "---------------------"
}

getLatestPackages() {
    local skip_ansible=0
    for arg in "$@"; do
        [ "$arg" = "--skip-ansible" ] && skip_ansible=1
    done

    if isInternetAvailable; then
        _updateAsdf &
        _updateTldr &
        _updateTmuxinator &

        _updatePluginRepos
        _updateKubectlCompletion
        _updateSwitchCompletion
        _updateBrew

        if [ $skip_ansible -eq 0 ]; then
            ansible-playbook --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 $DOTFILES/ansible/git_setup.yaml
        fi
    else
        echo "No internet available, skipping getLatestPackages"
    fi

    wait
}

# One command to fully update this machine: pull dotfiles, upgrade packages,
# (re-)run the provisioning playbooks, and — on the work laptop — do the same for
# the workday overlay. Runs the work half only when $DOTFILES_WD is present.
updateMachine() {
    if ! isInternetAvailable; then
        echo "updateMachine: no internet, skipping." >&2
        return 1
    fi

    # 1. Pull the dotfiles repos themselves so we provision from the latest source.
    echo "==> Pulling dotfiles repos"
    git -C "$DOTFILES" pull --ff-only
    if [ -d "$DOTFILES_WD/.git" ]; then
        git -C "$DOTFILES_WD" pull --ff-only
    fi

    # 2. Upgrade packages / plugins / runtimes (updateMachine owns the Ansible runs,
    #    so skip the playbook inside getLatestPackages).
    echo "==> Updating packages"
    getLatestPackages --skip-ansible

    # 3. Provision: installs newly-declared casks/formulae/fonts + asdf runtimes,
    #    then relinks dotfiles and clones repos. provision.yaml fans out on
    #    ansible_os_family itself (no more uname branch here) and runs
    #    git_setup.yaml as its second play, so this is one invocation.
    echo "==> Provisioning"
    ansible-playbook --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 "$DOTFILES/ansible/provision.yaml"

    # 4. Work laptop only: workday tool repos, CLIs, and overlay playbook.
    if [ -d "$DOTFILES_WD" ] && command -v getLatestPackagesWD >/dev/null 2>&1; then
        echo "==> Updating workday overlay"
        getLatestPackagesWD
    fi

    echo "==> updateMachine complete"
}

isInternetAvailable() {
    ping -q -c1 google.com &>/dev/null
}

isTmuxSession() {
    [ "$TERM_PROGRAM" = "tmux" ]
}

# Assumes the caller has already confirmed internet availability
# (see getLatestPackages), so this doesn't re-ping per invocation.
getLatestFromGit() {
    if [ ! -d "$1" ]; then
        echo "-------GIT Clone------"
        echo $2
        git clone --depth 1 $2 $1
    else
        echo "-------GIT Pull-------"
        echo $2
        git -C $1 pull
    fi

    echo "----------------------"
}

dockerCleanContainers(){
    docker ps -q -a | xargs -I id sh -c 'docker stop id && docker rm id' 
}

# Restart Docker for Mac
# https://forums.docker.com/t/restart-docker-from-command-line/9420/8
dockerRestart() {
    docker ps -q | xargs -I id sh -c 'docker stop id && docker rm id' && 
        test -z "$(docker ps -q 2>/dev/null)" && 
        osascript -e 'quit app "Docker"' && 
        open -g /Applications/Docker.app && 
        while ! docker system info > /dev/null 2>&1; do sleep 1; done && 
        docker system prune -f --volumes
}

# updateKubeConfig(){
#     If there's already a kubeconfig file in ~/.kube/config it will import that too and all the contexts
#     DEFAULT_KUBECONFIG_FILE="$HOME/.kube/config"
#     if test -f "${DEFAULT_KUBECONFIG_FILE}"
#     then
#         export KUBECONFIG="$DEFAULT_KUBECONFIG_FILE"
#     fi 
#     # Your additional kubeconfig files should be inside ~/.kube/config-files
#     ADD_KUBECONFIG_FILES="$HOME/.kube/config-files"
#     mkdir -p "${ADD_KUBECONFIG_FILES}"
#     OIFS="$IFS"
#     IFS=$'\n'
#     for kubeconfigFile in `find "${ADD_KUBECONFIG_FILES}" -type f -maxdepth 1` #-name "*.yml" -o -name "*.yaml"`
#     do
#         export KUBECONFIG="$kubeconfigFile:$KUBECONFIG"
#     done
#     for kubeconfigFile in `find "${ADD_KUBECONFIG_FILES}" -type f -maxdepth 2 -name "kubeconfig"`
#     do
#         export KUBECONFIG="$kubeconfigFile:$KUBECONFIG"
#     done
#     IFS="$OIFS"
# }

watchDocker() {
    watch -n 5 'docker ps --format "table {{.Names}}\t{{.Status}}" -a'
}

watchK8Pods() {
    watch -n 5 "kubectl get pods | grep $1"
}

setupK8Proxy(){
    local port="${1:-8000}"
    kubectl proxy --port "$((port + 1))" --api-prefix=/api/v1/namespaces/
    # open http://localhost:8001/api/v1/namespaces/argocd/services/https:argocd-server:443/proxy/
}

proxyK8Service(){
    open http://localhost:$1/api/v1/namespaces/$2/services/https:$3:$4/proxy/
}

alias docker-restart=$dockerRestart

weather() {
    if ! [ -z "$1" ]; then
        curl "http://v2.wttr.in/${1}"
    else
        curl http://v2.wttr.in/dublin
    fi
}

testInternet(){
    local start=$SECONDS
    echo "Response Code from https://www.google.com"
    curl -w "%{http_code}" -o /dev/null -s https://www.google.com
    echo "Seconds:"
    echo $(( SECONDS - start ))
}

codec(){
    cd $1 && code .
}

cdc(){
    codec $1
}

tm(){
    if [ -z "$1" ]; then
        tmux list-sessions
        # read -p "Create new session ? " -n 1 -r

        echo -n 'Create new auto-named session ?'
        read REPLY
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            name="$(basename $PWD)"
            name="${name//\./-}"
        fi
        REPLY=
    else
        name=$1
    fi

    echo "Session name to use: $name"

    tmux has -t "=$name" && tmux attach -t "$name" && exit

    echo $name
    tmux new -d -s "$name"
    tmux attach -t "$name"
}

# toggleGlobalProtectConnection() {
#     osascript <<EOF
#         tell application "System Events" to tell process "GlobalProtect"
#             click menu bar item 1 of menu bar 2 -- Activates the GlobalProtect "window" in the menubar
#             set frontmost to true -- keep window 1 active
#             # log count button of window 1
#             # click button 1 of window 1
#             # log count button of window 1
#             # log count pop up button of window 1
#             tell window 1
#                 -- Click on the connect or disconnect button, depending on if they exist or not
#                 if exists (first UI element whose title is "Connect") then
#                     tell (first UI element whose title is "Connect") to if exists then click
#                 else
#                     tell (first UI element whose title is "Disconnect") to if exists then click
#                 end if
#             end tell
#             click menu bar item 1 of menu bar 2 -- This will close the GlobalProtect "window" after clicking Connect/Disconnect. This is optional.
#         end tell
# EOF
# }

# function switchDefaultEditor() {
#     export EDITOR="code --wait"
# }

function tmuxHPercent(){
    # Resolve the window this pane's shell is actually running in, rather than
    # relying on tmux's default "current" target (the client's attached window),
    # which is wrong when other panes are set up in a window you've switched away from.
    window_target="$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}')"
    height="$(tmux display-message -p -t "$window_target" '#{window_height}')"
    echo $height
    newHeight=$(echo "$height/100*$1" | bc -l | xargs printf %.0f)
    echo $newHeight
    tmux resize-pane -y $newHeight -t "${window_target}.$2"
}

function tmuxVPercent(){
    # See tmuxHPercent for why we resolve the window explicitly via $TMUX_PANE.
    window_target="$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}')"
    width="$(tmux display-message -p -t "$window_target" '#{window_width}')"
    echo $width
    newWidth=$(echo "$width/100*$1" | bc -l | xargs printf %.0f)
    echo $newWidth
    tmux resize-pane -x $newWidth -t "${window_target}.$2"
}

function tmuxUp(){
    tmux resize-pane -D $1
}

function tmuxDown(){
    tmux resize-pane -D $1
}

function sourceEnvFile(){
    set -a # automatically export all variables
    source .env
    set +a
}

function finder {
  if (( ! $# )); then
    open_command $PWD
  else
    open_command $@
  fi
}

function gitShallowCloneToFull(){
    git fetch --unshallow
}

function findLatestFile(){
    find $1 -maxdepth 1 -type f -exec ls -t {} + | head -1
}

function findLatestDownload(){
    findLatestFile "$HOME/Downloads"
}

function findLatestScreenshot(){
    findLatestFile "$HOME/Documents/Screenshots"
}

function copyLatestFile(){
    latestFile=$(findLatestFile "$1")
    echo "Copying latest file: $latestFile"
    pbcopy < "$latestFile"
}

function copyLatestImage(){
    latestImage=$(findLatestFile "$1")
    echo "Copying latest image: $latestImage"
    osascript -e "set the clipboard to (read (POSIX file \"$latestImage\") as JPEG picture)"
}

function copyLatestDownload(){
    copyLatestFile "$HOME/Downloads"
}

function copyLatestScreenshot(){
    copyLatestImage "$HOME/Documents/Screenshots"
}

function replaceInFiles(){
    FILENAME_TO_FIND=$1
    SEARCH_TEXT_INPUT=$2
    REPLACEMENT_INPUT=$3
    SEARCH_DIR="."

    # Handle search text - can be direct text or a file path
    if [ -f "$SEARCH_TEXT_INPUT" ]; then
        echo "Reading search text from file: $SEARCH_TEXT_INPUT"
        SEARCH_TEXT=$(< "$SEARCH_TEXT_INPUT" tr -d '\r')
    else
        SEARCH_TEXT="$SEARCH_TEXT_INPUT"
    fi

    # Handle replacement text - can be direct text or a file path
    if [ -f "$REPLACEMENT_INPUT" ]; then
        echo "Reading replacement text from file: $REPLACEMENT_INPUT"
        REPLACEMENT_TEXT=$(< "$REPLACEMENT_INPUT" tr -d '\r')
    else
        REPLACEMENT_TEXT="$REPLACEMENT_INPUT"
    fi

    # Use 'find' to locate target files and process them
    echo "Searching for '$FILENAME_TO_FIND' under '$SEARCH_DIR'..."
    find "$SEARCH_DIR" -mindepth 2 -name "$FILENAME_TO_FIND" -type f -print0 | while IFS= read -r -d $'\0' TARGET_FILE; do

        echo "Processing: $TARGET_FILE"

        # Use perl for more reliable multiline search and replace
        # Read entire file, do literal string replacement (quotemeta escapes special chars)
        SEARCH="$SEARCH_TEXT" REPLACE="$REPLACEMENT_TEXT" perl -i -0777 -pe '$search = quotemeta($ENV{SEARCH}); $replace = $ENV{REPLACE}; s/$search/$replace/g' "$TARGET_FILE"
    done
}

function dockerBuild(){
    docker build --network=host -t $(basename "$PWD"):latest-local .
}

function dockerPull(){
    if [ -n "$1" ]; then
        image="$DOCKER_DEFAULT_REGISTRY_ADDRESS/$1"
        docker pull $image
    elif [ -n "$DOCKER_IMAGE" ]; then
        docker pull $DOCKER_IMAGE
    else
        echo "No image specified to pull"
    fi
}

function setDockerImage(){
    export DOCKER_IMAGE="$DOCKER_DEFAULT_REGISTRY_ADDRESS/$1"
}

function dockerRun(){
    if [ -n "$2" ]; then
        image="$DOCKER_DEFAULT_REGISTRY_ADDRESS/$2"
        docker run --rm -it --entrypoint $1 --network=host $image
    elif [ -n "$1" ]; then
        docker run --rm -it --network=host $(basename "$PWD"):latest-local $1
    elif [ -n "$DOCKER_IMAGE" ]; then
        docker run --rm -it --network=host $DOCKER_IMAGE
    else
        echo "No command or image specified to run"
    fi
}

# Decrypt a sops-encrypted file only if content has changed, to avoid
# unnecessary writes that would trigger sops-watch to re-encrypt.
_sops_decrypt_if_changed() {
    local enc="$1" dest="$2" input_type="$3" output_type="${4:-$3}"
    [ -s "$enc" ] || return 0
    local tmp
    tmp=$(mktemp)
    sops decrypt --input-type "$input_type" --output-type "$output_type" "$enc" > "$tmp"
    if ! cmp -s "$tmp" "$dest"; then
        mv "$tmp" "$dest"
    else
        rm "$tmp"
    fi
}

# Sets env vars required to build/install a Ruby version via asdf.
# Call manually before running `asdf install ruby <version>`.
rubyBuildEnv() {
  local brew_prefix
  brew_prefix="$(brew --prefix)"
  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=${brew_prefix}/opt/openssl@3"
  export RUBY_CFLAGS="-w"
  export optflags="-Wno-error=implicit-function-declaration"
  export LDFLAGS="-L${brew_prefix}/opt/readline/lib -L${brew_prefix}/opt/libffi/lib"
  export CPPFLAGS="-I${brew_prefix}/opt/readline/include -I${brew_prefix}/opt/libffi/include"
  export PKG_CONFIG_PATH="${brew_prefix}/opt/readline/lib/pkgconfig:${brew_prefix}/opt/libffi/lib/pkgconfig"
  echo "Ruby build env set (prefix: ${brew_prefix})"
}

rbBuildEnv() {
  rubyBuildEnv
}