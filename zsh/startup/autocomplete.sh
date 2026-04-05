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
# Try multiple common asdf installation locations
if [ -f "$HOME/.asdf/asdf.sh" ]; then
	. "$HOME/.asdf/asdf.sh"
elif [ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]; then
	. "/opt/homebrew/opt/asdf/libexec/asdf.sh"
elif [ -f "/usr/local/opt/asdf/libexec/asdf.sh" ]; then
	. "/usr/local/opt/asdf/libexec/asdf.sh"
elif [ -f "/home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh" ]; then
	. "/home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh"
fi

# Append completions to fpath if ASDF_DIR is set
if [ -n "${ASDF_DIR}" ]; then
	fpath=(${ASDF_DIR}/completions $fpath)
fi

#AWS
if [ -d "$HOME/.awsume/zsh-autocomplete" ]; then
	#AWSume alias to source the AWSume script
	alias awsume="source awsume"
	#Auto-Complete function for AWSume
	fpath=(~/.awsume/zsh-autocomplete/ $fpath)
fi