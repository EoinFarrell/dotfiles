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
SOPS_CONFIG=~/.config/sops/sops.yaml
export EDITOR=hx

# Decrypt and export environment variables from encrypted .env file
if [ -r "$DOTFILES/zsh/.env.enc" ]; then
    eval "$(sops decrypt --input-type dotenv --output-type dotenv $DOTFILES/zsh/.env.enc | sed 's/^/export /')"
fi

# loop or direct options
for f in $DOTFILES/zsh/startup/*; do source $f;done

if [ -r "$DOTFILES_WD/zsh/init.sh" ]; then
	source "$DOTFILES_WD/zsh/init.sh"
fi