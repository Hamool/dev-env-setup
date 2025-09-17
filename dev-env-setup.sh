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

TO_INSTALL=()

mapfile -t PACKAGES < packages.txt

# build fzf from source and add config to bashrc

remove_package() {
  local remove=$1
  local new_pkgs=()

  for pkg in "${PACKAGES[@]}"; do
    if [[ "$pkg" != "$remove" ]]; then
      new_pkgs+=("$pkg")
    fi
  done
  PACKAGES=("${new_pkgs[@]}")
}

install_packages() {
  if command -v apt >/dev/null 2>&1; then 
    sudo apt install -y $1
  elif command -v dnf >/dev/null 2>&1; then 
    sudo dnf install -y $1
  elif command -v pacman >/dev/null 2>&1; then 
    sudo pacman -S --noconfirm $1
  fi
}

if [[ "${PACKAGES[@]}" =~ "fzf" ]]; then 
  echo "Building fzf from source"
  remove_package "fzf"
  fzf_home=$HOME/.fzf
  if [[ ! -d $HOME/.fzf ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git $fzf_home
    $fzf_home/install --all
  else
    echo "fzf already cloned to $HOME/.fzf"
    cd $fzf_home
    git pull
    $fzf_home/install --all
    cd -
  fi
fi

if [[ "${PACKAGES[@]}" =~ "nvim" ]]; then
  echo "Building nvim from source"
  remove_package "nvim"

  # Install build dependencies (Debian/Ubuntu/Fedora/Arch)
  if command -v apt >/dev/null 2>&1; then
    sudo apt install -y ninja-build gettext cmake unzip curl build-essential
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y ninja-build libtool gcc make cmake curl unzip gettext
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm base-devel cmake unzip ninja curl gettext
  else
    echo "⚠️  Unknown package manager. Please install Neovim build deps manually."
  fi

  nvim_home=$HOME/nvim_src
  if [[ ! -d "$nvim_home" ]]; then
    git clone https://github.com/neovim/neovim.git "$nvim_home"
  fi
    cd $nvim_home
    git pull
    make CMAKE_BUILD_TYPE=Release
    sudo make install
    cd -
fi

for pkg in "${PACKAGES[@]}"; do
  if ! command -v "$pkg" >/dev/null 2>&1; then
    TO_INSTALL+=("$pkg")
  fi
done
if [ ! ${#TO_INSTALL[@]} -gt 0 ]; then 
  echo "Nothing to install"
else
  install_packages ${PACKAGES[@]}
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
