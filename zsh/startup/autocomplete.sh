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
# Modern asdf (0.16+, installed as a Homebrew binary) has no asdf.sh to
# source — you put its shims dir on PATH yourself. The old sourcing block
# here matched none of the pre-0.16 layouts, so shims never loaded and
# `go`/`node` were invisible despite `asdf list` showing them installed.
if command -v asdf >/dev/null 2>&1; then
	export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
	path=("$ASDF_DATA_DIR/shims" $path)
	# _asdf completion is already reachable: Homebrew symlinks it into
	# $HOMEBREW_PREFIX/share/zsh/site-functions, which brew shellenv puts
	# on fpath. Nothing to add here.
fi

#AWS
if [ -d "$HOME/.awsume/zsh-autocomplete" ]; then
	#AWSume alias to source the AWSume script
	alias awsume="source awsume"
	#Auto-Complete function for AWSume
	fpath=(~/.awsume/zsh-autocomplete/ $fpath)
fi