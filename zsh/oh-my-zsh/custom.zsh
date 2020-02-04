DOTFILES=~/Code/dotfiles
alias weather="curl http://v2.wttr.in"

#LSD
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# HSTR configuration - add this to ~/.bashrc
alias hh=hstr                    # hh to be alias for hstr
export HISTFILE=~/.zsh_history  # ensure history file visibility
export HSTR_CONFIG=hicolor        # get more colors
#bindkey -s "\C-r" "\eqhstr\n"     # bind hstr to Ctrl-r (for Vi mode check doc)

# Colorise the top Tabs of Iterm2 with the same color as background
# Just change the 18/26/33 wich are the rgb values
echo -e "\033]6;1;bg;red;brightness;18\a"
echo -e "\033]6;1;bg;green;brightness;26\a"
echo -e "\033]6;1;bg;blue;brightness;33\a"

eval "$(rbenv init -)"