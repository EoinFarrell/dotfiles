autoload -Uz compinit 
# https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=2978873
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
	compinit;
else
	compinit -C;
fi;

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src


## KubeSwitch
## TODO Fix this
source <(switcher init zsh)
# source <(switch completion zsh) # this is now handled by zsh plugin
alias kubectx='switch'


## Replace with https://github.com/mkokho/kubemrr
## Or re-enable kubectl plugin
# get zsh complete kubectl
# source <(kubectl completion zsh) # this is now handled by zsh plugin
alias kubectl=kubecolor
# # make completion work with kubecolor
compdef kubecolor=kubectl


# ASDF
. "$HOME/.asdf/asdf.sh"
# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)


#AWS
#AWSume alias to source the AWSume script
alias awsume="source awsume"
#Auto-Complete function for AWSume
fpath=(~/.awsume/zsh-autocomplete/ $fpath)