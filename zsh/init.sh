DOTFILES=~/Code/personal/dotfiles
NOTES=~/Code/personal/notes.eoinfarrell.dev
VMWARE=~/Code/VMWare
CAUA=~/Code/VMWare/CAUA

source $DOTFILES/zsh/functions.sh

getLatestPackages() {
  func_result="$(isTmuxSession)"

  if [ $func_result  -eq 0 ]; then
    brew outdated

    PLUGINSD=$ZSH_CUSTOM/plugins

    DIRECTORY=$PLUGINSD/zsh-autosuggestions
    getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-autosuggestions"

    DIRECTORY=$PLUGINSD/zsh-syntax-highlighting
    getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-syntax-highlighting"

    DIRECTORY=$PLUGINSD/zsh-autosuggestions
    getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-completions"
    fpath+=$DIRECTORY/src

    THEMESD=$HOME/.oh-my-zsh/custom/themes
    DIRECTORY=$THEMESD/powerlevel10k
    getLatestFromGit $DIRECTORY "https://github.com/romkatv/powerlevel10k.git"

    $HOME/.asdf/bin/asdf update
    tldr --update

    python3 -m pip install --upgrade pip
  else
    echo 'Tmux session - Latest from Github not pulled'
  fi
}

getLatestPackages