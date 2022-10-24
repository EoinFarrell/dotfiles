#!/bin/bash

isInternetAvailable() {
    ping -q -c1 google.com &>/dev/null
    if [ $? -eq 0 ]; then
        echo "1"
    else
        echo "0"
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
            git clone $2 $1
        else
            git -C $1 pull
        fi
    fi
}