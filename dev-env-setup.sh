#! /bin/bash

set -euo pipefail

trap 'echo "[ERROR] Script failed at line $LINENO. Check $LOGFILE for details." >&2' ERR
# enable logging 

trap 'if [[ $STATUS == "ok" ]]; then
          echo "=== Setup finished successfully at $(date) ===";
          exit 0
      fi' EXIT

LOGFILE="$HOME/dev-env-setup.log"

if [ -f "$LOGFILE" ] && [ $(wc -l < "$LOGFILE") -gt 1000 ]; then
  mv "$LOGFILE" "$LOGFILE.$(date +%Y%m%d-%H%M%S)" 
fi

exec > >(tee -a "$LOGFILE") 2>&1
echo ""
echo "=== Run started at $(date) ==="

mapfile -t PACKAGES < packages.txt

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

detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        OS="macOS"
    elif [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS="$NAME $VERSION_ID"
    else
        OS="Unknown"
    fi
}

detect_package_manager() {
  if command -v apt >/dev/null 2>&1; then 
    PM="apt"
    UPDATE_CMD="sudo apt update -y"
    INSTALL_CMD="sudo apt install -y"
  elif command -v dnf >/dev/null 2>&1; then 
    PM="dnf"
    UPDATE_CMD="sudo dnf check-update -y"
    INSTALL_CMD="sudo dnf install -y"
  elif command -v pacman >/dev/null 2>&1; then 
    PM="pacman"
    UPDATE_CMD="sudo pacman -Sy --noconfirm"
    INSTALL_CMD="sudo pacman -S --noconfirm"
  elif command -v apk >/dev/null 2>&1; then 
    PM="apk"
    UPDATE_CMD="sudo apk update"
    INSTALL_CMD="sudo apk add"
  elif command -v brew >/dev/null 2>&1; then 
    PM="brew"
    UPDATE_CMD="brew update"
    INSTALL_CMD="brew install"
  else
    echo "Unsupported package manager. Aborting."
    exit 1
  fi

  echo ">>> Detected OS: $OS"
  echo ">>> Using package manager: $PM"
}

update_and_build() {
    local repo_url="$1"
    local dest_dir="$2"
    shift 2
    local build_cmds=("$@")

    if [[ ! -d "$dest_dir/.git" ]]; then
        echo "Cloning repository: $repo_url → $dest_dir"
        git clone "$repo_url" "$dest_dir"
        cd "$dest_dir"
        "${build_cmds[@]}"
        cd -
    else
        echo "Updating repository in $dest_dir"
        cd "$dest_dir"
        OLD_HASH=$(git rev-parse HEAD)
        git pull --quiet
        NEW_HASH=$(git rev-parse HEAD)

        if [[ "$OLD_HASH" != "$NEW_HASH" ]]; then
            echo "New commits found → running build commands"
            "${build_cmds[@]}"
        else
            echo "Already up-to-date → skipping build"
        fi
        cd -
    fi
}

detect_os
detect_package_manager
eval "$UPDATE_CMD"

if [[ "${PACKAGES[@]}" =~ "fzf" ]]; then 
  echo "Building fzf from source"
  remove_package "fzf"
  fzf_home=$HOME/.fzf
  
  update_and_build \
    "https://github.com/junegunn/fzf.git" \
    "$fzf_home" \
    ./install --all
fi

if [[ "${PACKAGES[@]}" =~ "nvim" ]]; then
  echo "Building nvim from source"
  remove_package "nvim"

  # Install build dependencies (Debian/Ubuntu/Fedora/Arch/Artix/MacOS)
  if command -v apt >/dev/null 2>&1; then
    sudo apt install -y ninja-build gettext cmake unzip curl build-essential
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y ninja-build libtool gcc make cmake curl unzip gettext
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm base-devel cmake unzip ninja curl gettext
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add --no-cache \
      build-base cmake curl unzip gettext-tiny gettext-tiny-dev lua5.1-dev
  elif command -v brew >/dev/null 2>&1; then
    brew install ninja cmake gettext curl unzip
    brew link gettext --force
  else
    echo "Unknown package manager. Please install Neovim build deps manually."
  fi

  nvim_home=$HOME/nvim_src
  update_and_build \
    "https://github.com/neovim/neovim.git " \
    "$nvim_home" \
    make CMAKE_BUILD_TYPE=Release \
    sudo make install
fi

# update package database and install packages
if [ ! ${#PACKAGES[@]} -gt 0 ]; then 
  echo "Nothing to install"
else
  eval "$INSTALL_CMD ${PACKAGES[@]}"
fi


# create ~/projects dir if it doesn't exist

if [[ -d "~/projects" ]]; then
  mkdir ~/projects
  echo "~/projects directory creates" 
else 
  echo "~/projects directory already exists"
fi

source $HOME/.bashrc

STATUS="ok"
