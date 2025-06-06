#!/usr/bin/env bash

set -e
set -u

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "This script is intended to run on macOS only."
  exit 1
fi

# Install Homebrew if not already installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ $(uname -m) == 'arm64' ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Update Homebrew and install packages
echo "Updating Homebrew and installing packages..."
brew update
brew bundle || { echo "Failed to install packages from Brewfile."; exit 1; }

# Import GPG key from 1Password
echo "Setting up GPG key from 1Password..."
source "$(dirname "$0")/scripts/import_gpg.sh"

# Install dotfiles with Dotdrop
echo "Installing dotfiles with Dotdrop..."
dotdrop install -p PUB-MAC-BRASA

# Setup Zgenom for Zsh plugin management
ZGENOM_DIR="${HOME}/.zgenom"
if [ ! -d "$ZGENOM_DIR" ]; then
  echo "Installing Zgenom..."
  git clone https://github.com/jandamm/zgenom.git "${ZGENOM_DIR}"
fi

echo "BootKit setup complete! Please restart your terminal."
