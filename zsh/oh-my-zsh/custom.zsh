# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix

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
export HISTFILESIZE=10000000
# increase history size (default is 500)
export HISTSIZE=${HISTFILESIZE}
#save history after logout
export SAVEHIST=10000000

setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.

# HSTR configuration
alias hh=hstr                    # hh to be alias for hstr
export HISTFILE=~/.zsh_history  # ensure history file visibility
export HSTR_CONFIG=hicolor        # get more colors
#bindkey -s "\C-r" "\eqhstr\n"     # bind hstr to Ctrl-r (for Vi mode check doc)

# Colorise the top Tabs of Iterm2 with the same color as background
# Just change the 18/26/33 wich are the rgb values
# echo -e "\033]6;1;bg;red;brightness;18\a"
# echo -e "\033]6;1;bg;green;brightness;26\a"
# echo -e "\033]6;1;bg;blue;brightness;33\a"

export TERM="xterm-256color"

source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/

# eval "$(rbenv init -)"

# export PATH="$HOME/.jenv/bin:$PATH"
# eval "$(jenv init -)"

# eval $(minikube docker-env)

# Go development
# export GOPATH="${HOME}/.go"
# export GOROOT="$(brew --prefix golang)/libexec"
# export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"
# test -d "${GOPATH}" || mkdir "${GOPATH}"
# test -d "${GOPATH}/src/github.com" || mkdir -p "${GOPATH}/src/github.com"

# Google Cloud Builder Sdk
# The next line updates PATH for the Google Cloud SDK.
# source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc
# The next line enables zsh completion for gcloud.
# source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
# export CLOUDSDK_PYTHON=python3

# # Add alias for todo.txt
# export TODOTXT_DEFAULT_ACTION=ls
# alias t='todo.sh'
# # Add auto completion for todo.txt
# complete -F _todo t

# get zsh complete kubectl
source <(kubectl completion zsh)
alias kubectl=kubecolor
# make completion work with kubecolor
compdef kubecolor=kubectl


# ASDF

. "$HOME/.asdf/asdf.sh"
# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
# autoload -Uz compinit && compinit
. ~/.asdf/plugins/java/set-java-home.zsh
# alias go-reshim='asdf reshim golang && export GOROOT="$(asdf where golang)/go/"'
# . /usr/local/opt/asdf/asdf.sh

# export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export PATH="$HOME/Library/Python/3.9/bin:$PATH"

#AWS

#AWSume alias to source the AWSume script
alias awsume="source awsume"
#Auto-Complete function for AWSume
fpath=(~/.awsume/zsh-autocomplete/ $fpath)

export PATH=${PATH/\/Users\/feoin\/.nix-profile\/bin:}
export PATH=${PATH/\/nix\/var\/nix\/profiles\/default\/bin:}
export PATH=${PATH/\/Users\/feoin\/.nix-profile\/bin:}
export PATH=${PATH/\/nix\/var\/nix\/profiles\/default\/bin:}
export PATH=${PATH/\/Users\/eoinfarrell\/Library\/Application Support\/JetBrains\/Toolbox\/scripts:}
export PATH=${PATH/\/Users\/eoinfarrell\/Library\/Application Support\/JetBrains\/Toolbox\/scripts}
export PATH=${PATH/\/var\/run\/com.apple.security.cryptexd\/codex.system\/bootstrap\/usr\/local\/bin:}
export PATH=${PATH/\/var\/run\/com.apple.security.cryptexd\/codex.system\/bootstrap\/usr\/bin:}
export PATH=${PATH/\/var\/run\/com.apple.security.cryptexd\/codex.system\/bootstrap\/usr\/appleinternal\/bin:}

