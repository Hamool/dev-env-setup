#! /bin/bash

# TODO:
#
# - install nvim, tmux, git, htop, wget, curl, fzf
# - add fzf to bashrc
# - create ~/projects directory

# update package db

echo "Updating package database"
if command -v apt >/dev/null 2>&1; then 
  sudo apt update -y
elif command -v dnf >/dev/null 2>&1; then 
  sudo dnf check-update -y || true
elif command -v pacman >/dev/null 2>&1; then 
  sudo pacman -Sy --noconfirm
fi

PACKAGES=(nvim tmux git htop wget curl fzf)
TO_INSTALL=()

echo "Installing packages"
for pkg in "${PACKAGES[@]}"; do
  if ! command -v "$pkg" >/dev/null 2>&1; then
    TO_INSTALL+=("$pkg")
  fi
done
if [ ${#TO_INSTALL[@]} -gt 0 ]; then 
  if command -v apt >/dev/null 2>&1; then 
    sudo apt install -y ${TO_INSTALL[*]}
  elif command -v dnf >/dev/null 2>&1; then 
    sudo dnf install -y ${TO_INSTALL[*]}
  elif command -v pacman >/dev/null 2>&1; then 
    sudo pacman -S --noconfirm ${TO_INSTALL[*]}
  fi
else
  echo "Nothing to install"
fi
# update package database and install packages


# create ~/projects dir if it doesn't exist

if [[ -d "~/projects" ]]; then
  mkdir ~/projects
  echo "~/projects directory creates" 
else 
  echo "~/projects directory already exists"
fi

# add fzf to .bashrc but only if it's not already there

grep -Fxq 'eval "$(fzf --bash)"' "$HOME/.bashrc" || echo 'eval "$(fzf --bash)"' >> "$HOME/.bashrc"
