# dotfiles

## How To

### Symlink - Create
ln -s ~/Code/dotfiles/... ~/.

### SymLink - Update
ln -sf ~/Code/dotfiles/... ~/.


## Links

- https://github.com/robbyrussell/oh-my-zsh/blob/master/README.md
- https://sourabhbajaj.com/mac-setup/iTerm/zsh.html
- https://medium.com/@Clovis_app/configuration-of-a-beautiful-efficient-terminal-and-prompt-on-osx-in-7-minutes-827c29391961
- https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md
- https://github.com/powerline/fonts/blob/master/Meslo%20Slashed/Meslo%20LG%20M%20Regular%20for%20Powerline.ttf

# clone
git clone https://github.com/powerline/fonts.git --depth=1
# install
cd fonts
./install.sh
# clean-up a bit
cd ..
rm -rf fonts

# TODO

- Ansible improvements
  - https://github.com/jamesdh/dotfiles/blob/8fbe5409c6bb26bce9d50e2328359f5a37edd716/roles/osx/tasks/per_app/iterm.yml
