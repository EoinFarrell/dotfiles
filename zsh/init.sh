DOTFILES=~/Code/personal/dotfiles

source $DOTFILES/zsh/functions.sh

func_result="$(isTmuxSession)"

if [ $func_result  -eq 0 ]; then
  brew outdated & disown

  PLUGINSD=$ZSH_CUSTOM/plugins

  DIRECTORY=$PLUGINSD/zsh-autosuggestions
  getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-autosuggestions" & disown

  DIRECTORY=$PLUGINSD/zsh-syntax-highlighting
  getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-syntax-highlighting" & disown

  DIRECTORY=$PLUGINSD/zsh-autosuggestions
  getLatestFromGit $DIRECTORY "https://github.com/zsh-users/zsh-completions" & disown
  fpath+=$DIRECTORY/src

  THEMESD=$HOME/.oh-my-zsh/custom/themes
  DIRECTORY=$THEMESD/powerlevel10k
  getLatestFromGit $DIRECTORY "https://github.com/romkatv/powerlevel10k.git" & disown
else
  echo 'Tmux session - Latest from Github not pulled'
fi
