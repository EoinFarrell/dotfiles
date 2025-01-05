# Uncomment the following line to automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

zstyle ':omz:plugins:git' aliases no
zstyle ':omz:plugins:docker' aliases no
zstyle ':omz:plugins:docker-compose' aliases no

# case insensitive completion
# https://stackoverflow.com/a/24237590
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate _prefix
# setopt menu_complete
