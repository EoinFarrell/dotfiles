#!/bin/bash
jq -s '{"Profiles": .}' <~/Code/personal/dotfiles/iterm2/iterm2Profile.json >~/Code/personal/dotfiles/iterm2/iterm2DynamicProfile.json