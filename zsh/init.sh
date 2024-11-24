CODE=~/Code
PERSONAL=~/Code/personal
DOTFILES=~/Code/personal/dotfiles
NOTES=~/Code/personal/notes.eoinfarrell.dev
HOMELAB=~/Code/personal/homelab.eoinfarrell.dev
AWS_CONFIG=~/.aws
KUBE_CONFIG=~/.kube
SSH_CONFIG=~/.ssh

source $DOTFILES/zsh/functions.sh
source $DOTFILES/zsh/workday-functions.sh

# exec tmux
# tmux new-session -d -s htop-session 'htop';  # start new detached tmux session, run htop
# tmux split-window;                             # split the detached tmux session
# tmux send 'htop -t' ENTER;                     # send 2nd command 'htop -t' to 2nd pane. I believe there's a `--target` option to target specific pane.
# tmux a;                                        # open (attach) tmux session.

# if [ $func_result  -eq 1 ]; then

#   tmux ls && read "?Select a session<default>:" tmux_session && tmux attach -t ${tmux_session:-default} || tmux new -s ${tmux_session:-default}
  
  
# else
#   SESSION_NAME=$(tmux display-message -p '#S')
#   if [ "$SESSION_NAME" = "default" ]; then
#     echo 'Default window'
#     tmux new-window getLatestPackages
#   fi

#   echo 'Tmux session - Latest from Github not pulled'
# fi