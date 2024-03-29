PERSONAL=~/Code/personal
DOTFILES=~/Code/personal/dotfiles
NOTES=~/Code/personal/notes.eoinfarrell.dev

source $DOTFILES/zsh/functions.sh

getLatestPackages() {
  func_result="$(isItermSession)"

  if [ $func_result  -eq 1 ]; then
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

    python3 -m pip install --upgrade pip &
  else
    echo 'Tmux session - Latest from Github not pulled'
  fi
}

getLatestPackages