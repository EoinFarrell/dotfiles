#!/bin/bash

alias runGoScript="(cd $DOTFILES/go-scripts; go run ./script.go)"

getLatestPackages() {
    # docker system prune -f --volumes

    $HOME/.asdf/bin/asdf update &
    tldr --update &
    gem update tmuxinator &

    PLUGINSD=$ZSH_CUSTOM/plugins

    DIRECTORY=$PLUGINSD/git-open
    getLatestFromGit $DIRECTORY "https://github.com/paulirish/git-open.git"

    DIRECTORY=$PLUGINSD/zsh-autosuggestions
    getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-autosuggestions"

    DIRECTORY=$PLUGINSD/zsh-syntax-highlighting
    getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-syntax-highlighting"

    DIRECTORY=$PLUGINSD/zsh-autocomplete
    getLatestFromGit $DIRECTORY https://github.com/marlonrichert/zsh-autocomplete.git
    # source $DIRECTORY/zsh-autocomplete.plugin.zsh

    DIRECTORY=$PLUGINSD/zsh-completions
    getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-completions"
    fpath+=$DIRECTORY/src

    THEMESD=$HOME/.oh-my-zsh/custom/themes
    DIRECTORY=$THEMESD/powerlevel10k
    getLatestFromGit $DIRECTORY "https://github.com/romkatv/powerlevel10k.git"

    # python3 -m pip install --upgrade pip &

    if command -v kubectl >/dev/null 2>&1
    then
        kubectl completion zsh > ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete/kubectl-autocomplete.plugin.zsh
    fi

    if command -v switch >/dev/null 2>&1
    then
        switch completion zsh > ~/.oh-my-zsh/custom/plugins/switch-autocomplete/switch-autocomplete.plugin.zsh
    fi
    
    if switch -v kubectl >/dev/null 2>&1
    then
        brew outdated --json | runGoScript | xargs brew upgrade
    
        echo "----Brew Outdated----"
        brew outdated
        echo "---------------------"
    fi

    ansible-playbook --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 $DOTFILES/ansible/git_setup.yaml

    wait
}

isInternetAvailable() {
    ping -q -c1 google.com &>/dev/null
    if [ $? -eq 0 ]; then
        echo "1"
    else
        echo "0"
    fi
}

isItermSession() {
    [ "$TERM_PROGRAM" = "iTerm.app" ]
    return
}


isTmuxSession() {
    if [ "$TERM_PROGRAM" != "tmux" ]; then
        echo "0"
    else
        echo "1"
    fi
}

getLatestFromGit() {
    func_result="$(isInternetAvailable)"
    if [ $func_result -eq 1 ]; then
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
    fi
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
    kubectl proxy --port $((port + 1)) --api-prefix=/api/v1/namespaces/
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
    watch -n 1 start=$SECONDS
    echo "Response Code from https://www.google.com"
    curl -w "%{http_code}" -o /dev/null -s https://www.google.com
    echo "Seconds:"
    echo $(( SECONDS - start ))
}

# todo(){
#     source $DOTFILES/zsh/scripts/todo.sh $1 todo $2 $3 $4

#     # if ! [ -z "$1" ]; then
#     #     echo "- ${1}" >> $NOTES/TODO.md
#     # else
#     #     mdcat $NOTES/TODO.md
#     # fi
# }

# todoDemo(){
#     source $DOTFILES/zsh/scripts/todo.sh $1 demo $2
# }

# cpConsts() {
#     source $DOTFILES/zsh/scripts/copy/copy.sh $1 $2 $3
# }

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
    height="$(tmux list-windows -F "#{window_height}" | head -n1)"
    echo $height
    newHeight=$(echo "$height/100*$1" | bc -l | xargs printf %.0f)
    echo $newHeight
    tmux resize-pane -y $newHeight -t $2
}

function tmuxVPercent(){
    width="$(tmux list-windows -F "#{window_width}" | head -n1)"
    echo $width
    newWidth=$(echo "$width/100*$1" | bc -l | xargs printf %.0f)
    echo $newWidth
    tmux resize-pane -x $newWidth -t $2
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

function dockerRun(){
    docker run --rm -it --network=host $(basename "$PWD"):latest-local $1
}