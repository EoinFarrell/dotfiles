/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/eoinfarrell/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install --cask firefox   
brew install --cask iterm2
brew install --cask visual-studio-code

brew install git

mkdir Code && cd Code && mkdir personal && cd personal
git clone https://github.com/EoinFarrell/dotfiles.git
brew install --cask spotify
brew install tmux
brew install zsh

brew install hstr
brew install lsd
brew install tig
brew install gh
gh auth login

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
rm ~/.zshrc
ln -s ~/Code/personal/dotfiles/zsh/zshrc ~/.zshrc
ln -s ~/Code/personal/dotfiles/zsh/oh-my-zsh/custom.zsh ~/.oh-my-zsh/custom/custom.zsh
chsh -s /usr/local/bin/zsh

ln -s ~/Code/personal/dotfiles/git/.gitconfig ~/.gitconfig
ln -s ~/Code/personal/dotfiles/tmux/.tmux.conf ~/.tmux.conf
ln -s ~/Code/personal/dotfiles/tig/.tigrc ~/.tigrc
ln -s ~/Code/personal/dotfiles/vim/.vimrc ~/.vimrc

# restart shell

# Prints something like '/bin/ksh' or '-zsh'
# See bottom section if you always need the full path.
ps -o comm= $$

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# complete setup

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