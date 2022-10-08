DOTFILES=~/Code/personal/dotfiles

source $DOTFILES/zsh/functions.sh

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
