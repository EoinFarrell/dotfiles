PERSONAL=~/Code/personal
DOTFILES=~/Code/personal/dotfiles
NOTES=~/Code/personal/notes.eoinfarrell.dev

source $DOTFILES/zsh/functions.sh

getLatestPackages() {
    docker system prune -f --volumes
    brew outdated

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

    $HOME/.asdf/bin/asdf update &
    tldr --update &

    # python3 -m pip install --upgrade pip &
}

func_result="$(isItermSession)"

if [ $func_result  -eq 1 ]; then
  getLatestPackages
else
  echo 'Tmux session - Latest from Github not pulled'
fi

# exec tmux
# tmux new-session -d -s htop-session 'htop';  # start new detached tmux session, run htop
# tmux split-window;                             # split the detached tmux session
# tmux send 'htop -t' ENTER;                     # send 2nd command 'htop -t' to 2nd pane. I believe there's a `--target` option to target specific pane.
# tmux a;                                        # open (attach) tmux session.

# if [ $func_result  -eq 1 ]; then

#   tmux ls && read "?Select a session<default>:" tmux_session && tmux attach -t ${tmux_session:-default} || tmux new -s ${tmux_session:-default}
  
  
# else
#   SESSION_NAME=$(tmux display-message -p '#S')
#   if [ "$SESSION_NAME" = "default" ]; then
#     echo 'Default window'
#     tmux new-window getLatestPackages
#   fi

#   echo 'Tmux session - Latest from Github not pulled'
# fi