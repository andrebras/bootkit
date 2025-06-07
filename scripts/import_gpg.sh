#!/usr/bin/env bash

set -e
set -u

# Check for dependencies
if ! command -v op >/dev/null 2>&1; then
  echo "1Password CLI (op) not found, installing..."
  brew install --cask 1password-cli
fi

echo "Signing in to 1Password CLI..."
eval $(op signin)

echo "Retrieving GPG key from 1Password..."
GPG_KEY="$(op read "op://Dotfiles/GPG Key/notes")" || {
  echo "Failed to retrieve GPG key from 1Password"
  echo "Make sure you have a secure note titled 'GPG Key' in your Dotfiles vault"
  exit 1
}

# Try to extract key identifier using various patterns
KEY_ID=$(echo "$GPG_KEY" | grep -oE "[0-9A-F]{40}" | head -n 1)
KEY_ID=${KEY_ID:-$(echo "$GPG_KEY" | grep -oE "[0-9A-F]{16}" | head -n 1)}
KEY_ID=${KEY_ID:-$(echo "$GPG_KEY" | grep -oE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" | head -n 1)}

# Step 1: Check if we have a key ID
[ -n "$KEY_ID" ] && echo "Using key identifier: $KEY_ID" || echo "No key identifier found"

# Step 2: Check if key is already imported (skip if no key ID)
ALREADY_IMPORTED=false
[ -n "$KEY_ID" ] && gpg --list-secret-keys "$KEY_ID" &>/dev/null && {
  echo "GPG key already imported, skipping import."
  ALREADY_IMPORTED=true
}

# Step 3: Import the key if not already imported
if [ "$ALREADY_IMPORTED" = false ]; then
  echo "Importing GPG key..."
  IMPORT_OUTPUT=$(echo "$GPG_KEY" | gpg --import 2>&1) || {
    echo "Failed to import GPG key"
    exit 1
  }
  echo "GPG key imported successfully"

  # Step 4: Try to extract key ID from import output if we didn't have one
  if [ -z "$KEY_ID" ]; then
    KEY_ID=$(echo "$IMPORT_OUTPUT" | grep -oE "key [0-9A-F]{16}:" | head -n 1 | cut -d' ' -f2 | tr -d ':')
    [ -n "$KEY_ID" ] && echo "Extracted key ID from import: $KEY_ID"
  fi
fi
