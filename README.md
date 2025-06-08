# Bootkit

A secure, reproducible developer environment bootstrapper for macOS that sets up your system with essential tools and configurations.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey)]()

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [What Gets Installed](#what-gets-installed)
- [Configuration](#configuration)
- [GPG Key Setup with 1Password](#gpg-key-setup-with-1password)
- [Directory Structure](#directory-structure)
- [Customizing](#customizing)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Overview

BootKit helps you set up a consistent development environment on macOS. It uses a declarative approach to define your tools and configurations, making it easy to restore your complete environment on a new machine or keep multiple machines in sync.

## Features

- **Homebrew Integration**: Installs packages from your Brewfile
- **Dotfile Management**: Manages configuration files with Dotdrop
- **Secure Credentials**: Imports GPG keys from 1Password
- **Shell Enhancement**: Sets up Zsh plugins with zgenom
- **Reproducibility**: Creates the same environment across machines
- **Idempotent**: Safe to run multiple times
- **Modular Design**: Uses Ruby components for maintainability
- **Configurable**: Simple YAML configuration

## Prerequisites

- macOS (tested on Sequoia 15.5)
- Terminal access
- 1Password account (for GPG key storage/retrieval)
- Git

## Installation

```bash
# Clone the repository
git clone git@github.com:you/bootkit.git ~/bootkit

# Navigate to the directory
cd ~/bootkit

# Create your configuration file from the example
cp bootkit.example.yml bootkit.yml

# Edit the configuration file to match your needs
nano bootkit.yml

# Run the installation script
./bin/install
```

## What Gets Installed

- Homebrew (if missing)
- All packages defined in Brewfile
- Your GPG key (retrieved from 1Password)
- Zgenom for Zsh plugin management
- Dotfiles (managed via Dotdrop)

## Configuration

### YAML Configuration

BootKit uses a simple YAML file for configuration. Copy the example file to get started:

```yaml
# 1Password Configuration
onepassword:
  vault: Dotfiles              # Name of your 1Password vault
  gpg_key_path: GPG Key/notes  # Path to your GPG key in 1Password

# GPG Configuration
gpg:
  key_id: ~                    # Optional: Specify your GPG key ID directly

# Dotdrop Configuration
dotdrop:
  profile: HOSTNAME            # Your dotdrop profile name (usually hostname)

# Logging Configuration
logging:
  level: info                  # Log level: debug, info, warn, error
```

Create and edit your configuration file:

```bash
# Create your configuration file
cp bootkit.example.yml bootkit.yml

# Edit the configuration file
nano bootkit.yml
```

> **Important**: The `bootkit.yml` file may contain sensitive information and is automatically added to `.gitignore`. Never commit this file to version control.

### Homebrew Packages

Edit the `Brewfile` to customize which packages, casks, and App Store applications to install:

```ruby
# Example Brewfile entries
brew "git"
brew "gpg"
brew "zsh"
cask "visual-studio-code"
mas "1Password", id: 1333542190
```

## GPG Key Setup with 1Password

BootKit can automatically import your GPG key from 1Password. To set this up:

1. Export your private GPG key:
   ```bash
   gpg --export-secret-keys -a YOUR_KEY_ID > private.key
   ```

2. Save it to a 1Password secure note:
   - Vault: `Dotfiles` (or the value specified in your `bootkit.yml` file)
   - Title: `GPG Key` (or the item name specified in your `bootkit.yml` file)
   - Store the key in the `notes` field (the default field in a secure note)

The installer will automatically retrieve this key and import it into your GPG keyring.

## Directory Structure

```
bootkit/
├── bin/                       # Executable scripts
│   └── install                # Main installation script
├── lib/                       # Ruby library files
│   ├── bootkit_helpers.rb     # Common helper functions
│   ├── brew_manager.rb        # Homebrew package management
│   ├── config_manager.rb      # Configuration loading and access
│   ├── dotfile_manager.rb     # Dotfile management via dotdrop
│   ├── gpg_manager.rb         # GPG key management
│   ├── installer.rb           # Main installer class
│   ├── key_identifier.rb      # GPG key identification functionality
│   ├── key_importer.rb        # GPG key import functionality
│   ├── onepassword_manager.rb # 1Password CLI management
│   ├── secrets_fetcher.rb     # Fetching secrets from 1Password
│   ├── system_manager.rb      # System compatibility checks
│   └── zgenom_manager.rb      # Zsh plugin management
├── Brewfile                   # Homebrew package definitions
├── bootkit.example.yml        # Example configuration template
├── bootkit.yml                # Your personal configuration (created from example)
├── README.md                  # This documentation
└── LICENSE                    # MIT License
```

## Customizing

### Adding New Packages

To add new packages, edit the `Brewfile`:

```ruby
# Add homebrew formulae
brew "your-package-name"

# Add casks (applications)
cask "your-application"

# Add Mac App Store applications
mas "App Name", id: 123456789
```

### Extending Functionality

The modular design makes it easy to extend BootKit:

1. Create a new manager class in `lib/` following the existing pattern
2. Add the new manager to the `Installer` class in `lib/installer.rb`
3. Update the configuration template if needed

## Troubleshooting

### Configuration File Missing

If you see an error about the configuration file missing:

```
ERROR: Configuration file not found: /path/to/bootkit.yml
```

Create your configuration file from the example:

```bash
cp bootkit.example.yml bootkit.yml
nano bootkit.yml  # Edit to match your needs
```

### GPG Key Import Issues

If you encounter issues with GPG key import:

1. Check that your 1Password vault and item names match your configuration
2. Ensure the GPG key is properly formatted in the notes field
3. Verify that you're signed in to 1Password CLI (`op signin`)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

BootKit integrates with and leverages several excellent tools:

### Open Source Tools
- [Homebrew](https://brew.sh/) - The missing package manager for macOS
- [Dotdrop](https://github.com/deadc0de6/dotdrop) - Save your dotfiles once, deploy them everywhere
- [zgenom](https://github.com/jandamm/zgenom) - A lightweight plugin manager for Zsh
- [GPG](https://gnupg.org/) - Complete and free implementation of the OpenPGP standard

### Proprietary Tools
- [1Password CLI](https://1password.com/downloads/command-line/) - Command-line interface for 1Password

I am grateful to the maintainers and contributors of these projects for their excellent work.
