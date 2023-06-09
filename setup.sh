/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"   
brew install --cask iterm2

brew install git

mkdir Code && cd Code && mkdir personal && cd personal
git clone https://github.com/EoinFarrell/dotfiles.git

brew install tmux
brew install zsh
brew install hstr
brew install lsd
brew install tig
brew install gh
brew install tree

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3

gh auth login

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
rm ~/.zshrc
ln -s ~/Code/personal/dotfiles/zsh/zshrc ~/.zshrc
ln -s ~/Code/personal/dotfiles/zsh/oh-my-zsh/custom.zsh ~/.oh-my-zsh/custom/custom.zsh
ln -s ~/Code/personal/dotfiles/zsh/oh-my-zsh/powerlevel10k.zsh ~/.oh-my-zsh/custom/powerlevel10k.zsh
ln -s ~/Code/personal/dotfiles/zsh/init.sh ~/.oh-my-zsh/custom/init.sh
chsh -s /usr/local/bin/zsh

ln -s ~/Code/personal/dotfiles/git/.gitignore ~/.gitignore
ln -s ~/Code/personal/dotfiles/git/.gitconfig ~/.gitconfig
ln -s ~/Code/personal/dotfiles/tmux/.tmux.conf ~/.tmux.conf
ln -s ~/Code/personal/dotfiles/tig/.tigrc ~/.tigrc
ln -s ~/Code/personal/dotfiles/vim/.vimrc ~/.vimrc
ln -s ~/Code/personal/dotfiles/asdf/.asdfrc ~/.asdfrc

# restart shell

# Prints something like '/bin/ksh' or '-zsh'
# See bottom section if you always need the full path.
ps -o comm= $$

#iterm setup
# install font: https://github.com/romkatv/powerlevel10k#manual-font-installation
# Create profile, set font to above 
# set colours to clovis-iterm-colour.itermcolors 

# Nix & Devbox setup
# https://github.com/jetpack-io/devbox
sh <(curl -L https://nixos.org/nix/install) --daemon
curl -fsSL https://get.jetpack.io/devbox | bash

#gui apps
brew install --cask zoom
brew install --cask slack
brew install --cask jetbrains-toolbox
brew install docker
brew install docker-compose

brew install --cask spotify
brew install --cask firefox
brew install --cask visual-studio-code

brew install kubectl
brew install kubecolor/tap/kubecolor
brew install jq

brew install --cask obsidian

# install https://getsynth.com
# export SYNTH_INSTALL_PATH=~/bin
# curl -sSL https://getsynth.com/install | sh
# synth telemetry disable