CODE=~/Code
PERSONAL=~/Code/personal
DOTFILES=~/Code/personal/dotfiles
DOTFILES_WD=~/Code/workday/eoin-farrell/dotfiles
WDDOTFILES=$DOTFILES_WD
WdDOTFILESD=$DOTFILES_WD
NOTES=~/Code/personal/notes.eoinfarrell.dev
HOMELAB=~/Code/personal/homelab.eoinfarrell.dev
AWS_CONFIG=~/.aws
KUBE_CONFIG=~/.kube
SSH_CONFIG=~/.ssh

source $DOTFILES/zsh/functions.sh

# loop or direct options
for f in $DOTFILES/zsh/startup/*; do source $f;done
# source $DOTFILES/zsh/startup/startup.sh

source $DOTFILES_WD/zsh/init.sh