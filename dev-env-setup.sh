#! /bin/bash

# TODO:
#
# - install nvim, tmux, git, htop, wget, curl, fzf
# - add fzf to bashrc
# - create ~/projects directory

# update package database and install packages

sudo apt update && sudo apt install -y nvim tmux git htop wget curl fzf

# create ~/projects dir if it doesn't exist

if [[ -d "~/projects` ]]; then
  mkdir ~/projects
  echo "~/projects directory creates" 
else 
  echo "~/projects directory already  exists"
fi

# add fzf to .bashrc but only if it's not already there

grep -Fxq 'eval "$(fzf --bash)"' "$HOME/.bashrc" || echo 'eval "$(fzf --bash)"' >> "$HOME/.bashrc"
