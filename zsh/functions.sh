#!/bin/bash

isInternetAvailable() {
    ping -q -c1 google.com &>/dev/null
    if [ $? -eq 0 ]; then
        echo "1"
    else
        echo "0"
    fi
}

isItermSession() {
    if [ "$TERM_PROGRAM" != "iTerm.app" ]; then
        echo "0"
    else
        echo "1"
    fi
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
            git clone --depth 1 $2 $1
        else
            git -C $1 pull
        fi
    fi
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

watchDocker() {
    watch -n 5 'docker ps --format "table {{.Names}}\t{{.Status}}" -a'
}

watchK8Pods() {
    watch -n 5 "kubectl get pods | grep $1"
}

alias docker-restart=$dockerRestart

weather() {
    if ! [ -z "$1" ]; then
        curl "http://v2.wttr.in/${1}"
    else
        curl http://v2.wttr.in/dublin
    fi
}   

todo(){
    source $DOTFILES/zsh/scripts/todo.sh $1 todo $2 $3 $4

    # if ! [ -z "$1" ]; then
    #     echo "- ${1}" >> $NOTES/TODO.md
    # else
    #     mdcat $NOTES/TODO.md
    # fi
}

todo-demo(){
    source $DOTFILES/zsh/scripts/todo.sh $1 demo $2
}

cp-consts() {
    source $DOTFILES/zsh/scripts/copy/copy.sh $1 $2 $3
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

toggleGlobalProtectConnection() {
    osascript <<EOF
        tell application "System Events" to tell process "GlobalProtect"
            click menu bar item 1 of menu bar 2 -- Activates the GlobalProtect "window" in the menubar
            set frontmost to true -- keep window 1 active
            # log count button of window 1
            # click button 1 of window 1
            # log count button of window 1
            # log count pop up button of window 1
            tell window 1
                -- Click on the connect or disconnect button, depending on if they exist or not
                if exists (first UI element whose title is "Connect") then
                    tell (first UI element whose title is "Connect") to if exists then click
                else
                    tell (first UI element whose title is "Disconnect") to if exists then click
                end if
            end tell
            click menu bar item 1 of menu bar 2 -- This will close the GlobalProtect "window" after clicking Connect/Disconnect. This is optional.
        end tell
EOF
}

function switchDefaultEditor() {
    export EDITOR="code --wait"
}