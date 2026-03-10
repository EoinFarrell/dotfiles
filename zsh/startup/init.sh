export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

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
export SOPS_CONFIG=~/.config/sops/sops.yaml
export EDITOR=hx

# Source functions needed by startup scripts
source ~/Code/personal/dotfiles/zsh/functions.sh

# Decrypt and export environment variables from encrypted .env file
if [ -r "$DOTFILES/zsh/.env.enc" ] && command -v sops >/dev/null 2>&1; then
    eval "$(sops decrypt --input-type dotenv --output-type dotenv $DOTFILES/zsh/.env.enc | sed 's/^/export /')"
fi

source $DOTFILES/zsh/startup/random.sh

if [ -r "$DOTFILES_WD/zsh/init.sh" ]; then
	source "$DOTFILES_WD/zsh/init.sh"
fi