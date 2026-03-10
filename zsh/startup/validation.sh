
if ! command -v tmux 2>&1 >/dev/null
then
    echo "tmux could not be found"
    return 1
fi

# if ! command -v tmuxinator 2>&1 >/dev/null
# then
#     echo "tmuxinator could not be found"
#     return 1
# fi

if ! command -v kubectx 2>&1 >/dev/null
then
    if ! command -v switcher 2>&1 >/dev/null
    then
        echo "kubectx or kubeswitch could not be found"
        return 1
    fi
fi