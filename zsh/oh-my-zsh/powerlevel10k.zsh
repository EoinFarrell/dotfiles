# function prompt_my_devbox() {
#     if [[ -z "${DEVBOX_SHELL_ENABLED}" ]]; then
#         return
#     else
#         p10k segment -i '</>' -f blue
#     fi
# }

source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

POWERLEVEL9K_KUBECONTEXT_CLASSES=(
    '*prd*'    prd
    '*stg*'    stg
    '*'        other
)

POWERLEVEL9K_KUBECONTEXT_PRD_BACKGROUND=red
POWERLEVEL9K_KUBECONTEXT_STG_BACKGROUND=yellow
POWERLEVEL9K_KUBECONTEXT_STG_FOREGROUND=black
POWERLEVEL9K_KUBECONTEXT_OTHER_BACKGROUND=blue

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(kubecontext)
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='red'

# POWERLEVEL9K_DIR_PACKAGE_FILES=(devbox.json)
POWERLEVEL9K_SHORTEN_STRATEGY=truncate_with_package_name
POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=false
# Don't shorten this many last directory segments. They are anchors.
POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
# Shorten directory if it's longer than this even if there is space for it. The value can
# be either absolute (e.g., '80') or a percentage of terminal width (e.g, '50%'). If empty,
# directory will be shortened only when prompt doesn't fit or when other parameters demand it
# (see POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS and POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT below).
# If set to `0`, directory will always be shortened to its minimum length.
POWERLEVEL9K_DIR_MAX_LENGTH=20

# Enable special styling for non-writable and non-existent directories. See POWERLEVEL9K_LOCK_ICON
# and POWERLEVEL9K_DIR_CLASSES below.
POWERLEVEL9K_DIR_SHOW_WRITABLE=v3

# The default icon shown next to non-writable and non-existent directories when
# POWERLEVEL9K_DIR_SHOW_WRITABLE is set to v3.
POWERLEVEL9K_LOCK_ICON='∅'

# Add a space in the first prompt
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%f"
# Visual customisation of the second prompt line
local user_symbol="$"
if [[ $(print -P "%#") =~ "#" ]]; then
    user_symbol = "#"
fi
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%{%B%F{black}%K{yellow}%} $user_symbol%{%b%f%k%F{yellow}%} %{%f%}"