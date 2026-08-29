# /bin/bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Bootstrap-only: ansible must exist before ansible-playbook can run and
# reconcile the rest of the machine. Ongoing package management for user/CLI
# tools happens via ansible/vars/homebrew_packages.yml, not here — see
# docs/adr/0001-homebrew-for-user-cli-tools.md.
brew install ansible

# brew install git

# mkdir Code && cd Code && mkdir personal && cd personal
# git clone https://github.com/EoinFarrell/dotfiles.git

# git clone https://github.com/asdf-vm/asdf.git ~/.asdf #--branch v0.11.3

gh auth login

# sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# rm ~/.zshrc
# ln -s ~/Code/personal/dotfiles/zsh/zshrc ~/.zshrc
# ln -s ~/Code/personal/dotfiles/zsh/oh-my-zsh/custom.zsh ~/.oh-my-zsh/custom/custom.zsh
# ln -s ~/Code/personal/dotfiles/zsh/oh-my-zsh/powerlevel10k.zsh ~/.oh-my-zsh/custom/powerlevel10k.zsh
# ln -s ~/Code/personal/dotfiles/zsh/init.sh ~/.oh-my-zsh/custom/init.sh
# chsh -s /usr/local/bin/zsh

# ln -s ~/Code/personal/dotfiles/git/.gitignore ~/.gitignore
# ln -s ~/Code/personal/dotfiles/git/.gitconfig ~/.gitconfig
# ln -s ~/Code/personal/dotfiles/tmux/.tmux.conf ~/.tmux.conf
# ln -s ~/Code/personal/dotfiles/tig/.tigrc ~/.tigrc
# ln -s ~/Code/personal/dotfiles/vim/.vimrc ~/.vimrc
# ln -s ~/Code/personal/dotfiles/asdf/.asdfrc ~/.asdfrc

# restart shell

# Prints something like '/bin/ksh' or '-zsh'
# See bottom section if you always need the full path.
ps -o comm= $$

#gui apps
# brew install --cask zoom
# brew install --cask slack
# brew install --cask jetbrains-toolbox
# brew install docker
# brew install docker-compose

# brew install --cask spotify
# brew install --cask firefox
# brew install --cask visual-studio-code

# brew install kubectl
# brew install kubecolor/tap/kubecolor
# brew install jq

# brew install --cask obsidian

