#!/usr/bin/env bash

set -e
set -u

# Check for dependencies
if ! command -v op >/dev/null 2>&1; then
  echo "1Password CLI (op) not found, installing..."
  brew install --cask 1password-cli
fi

# Check if user is signed in to 1Password
if ! op account list &>/dev/null; then
  echo "Please sign in to 1Password CLI first:"
  op signin
fi

# Get GPG key from 1Password
echo "Retrieving GPG key from 1Password..."
GPG_KEY=$(op read "op://Dotfiles/GPG Key/notes") || {
  echo "Failed to retrieve GPG key from 1Password"
  echo "Make sure you have a secure note titled 'GPG Key' in your Dotfiles vault"
  exit 1
}

# Extract key identifier from GPG key (email or fingerprint)
KEY_ID=$(echo "$GPG_KEY" | grep -oE "([0-9A-F]{8,40}|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})" | head -n 1)

# Check if key exists before importing
if [ -n "$KEY_ID" ] && gpg --list-keys "$KEY_ID" &>/dev/null; then
  echo "GPG key already imported."
else
  echo "Importing GPG key..."
  echo "$GPG_KEY" | gpg --import || {
    echo "Failed to import GPG key"
    exit 1
  }
  echo "GPG key imported successfully"
fi
