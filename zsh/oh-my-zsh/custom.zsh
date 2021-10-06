DOTFILES=~/Code/dotfiles
alias weather="curl http://v2.wttr.in/dublin"

#LSD
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

## History Settings
# leading space hides commands from history
export HISTCONTROL=ignorespace
# increase history file size (default is 500)
export HISTFILESIZE=10000
# increase history size (default is 500)
export HISTSIZE=${HISTFILESIZE}
#set history size
export HISTSIZE=10000
#save history after logout
export SAVEHIST=10000
#append into history file
setopt INC_APPEND_HISTORY
#save only one command if 2 common are same and consistent
setopt HIST_IGNORE_DUPS
#add timestamp for each entry
setopt EXTENDED_HISTORY   

# HSTR configuration
alias hh=hstr                    # hh to be alias for hstr
export HISTFILE=~/.zsh_history  # ensure history file visibility
export HSTR_CONFIG=hicolor        # get more colors
#bindkey -s "\C-r" "\eqhstr\n"     # bind hstr to Ctrl-r (for Vi mode check doc)

# Colorise the top Tabs of Iterm2 with the same color as background
# Just change the 18/26/33 wich are the rgb values
echo -e "\033]6;1;bg;red;brightness;18\a"
echo -e "\033]6;1;bg;green;brightness;26\a"
echo -e "\033]6;1;bg;blue;brightness;33\a"

export TERM="xterm-256color"

THEMESD=$HOME/.oh-my-zsh/custom/themes
DIRECTORY=$THEMESD/powerlevel9k
if [ ! -d "$DIRECTORY" ]; then
    git clone https://github.com/bhilburn/powerlevel9k.git $DIRECTORY
fi

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel9k/powerlevel9k"

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir rbenv vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(kubecontext time)
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='red'

# Add a space in the first prompt
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%f"
# Visual customisation of the second prompt line
local user_symbol="$"
if [[ $(print -P "%#") =~ "#" ]]; then
    user_symbol = "#"
fi
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%{%B%F{black}%K{yellow}%} $user_symbol%{%b%f%k%F{yellow}%} %{%f%}"

eval "$(rbenv init -)"

export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# eval $(minikube docker-env)

# Go development
export GOPATH="${HOME}/.go"
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"
test -d "${GOPATH}" || mkdir "${GOPATH}"
test -d "${GOPATH}/src/github.com" || mkdir -p "${GOPATH}/src/github.com"

# The next line updates PATH for the Google Cloud SDK.
source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc

# The next line enables zsh completion for gcloud.
source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc

# Add alias for todo.txt
export TODOTXT_DEFAULT_ACTION=ls
alias t='todo.sh'
# Add auto completion for todo.txt
complete -F _todo t

# Autocomplete for zsh
source <(kubectl completion zsh)

alias k="kubectl"
alias k=kubecolor
complete -F __start_kubectl k