#!/bin/bash
jq -s '{"Profiles": .}' <~/Code/personal/dotfiles/iterm2/iterm2Profile.json >~/Code/personal/dotfiles/iterm2/iterm2DynamicProfile.json
ln -s ~/Code/personal/dotfiles/iterm2/iterm2DynamicProfile.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/iterm2Profile.json