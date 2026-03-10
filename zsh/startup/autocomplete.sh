# These must come after compinit (run by OMZ above)

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

## KubeSwitch
if command -v switcher >/dev/null 2>&1; then
  source <(switcher init zsh)
  alias kubectx='switch'
fi

if command -v kubectl >/dev/null 2>&1; then
  export KUBECOLOR_KUBECTL=/opt/homebrew/bin/kubectl
  alias kubectl=kubecolor
  compdef kubecolor=kubectl
fi

# ASDF
if command -v asdf >/dev/null 2>&1
then
	. "$HOME/.asdf/asdf.sh"
	# append completions to fpath
	fpath=(${ASDF_DIR}/completions $fpath)
fi

#AWS
if command -v asdf >/dev/null 2>&1
then
	#AWSume alias to source the AWSume script
	alias awsume="source awsume"
	#Auto-Complete function for AWSume
	fpath=(~/.awsume/zsh-autocomplete/ $fpath)
fi