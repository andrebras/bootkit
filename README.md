# Bootkit

A secure, reproducible developer environment bootstrapper that sets up your macOS system with essential tools and configurations using declarative definitions.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey)]()

## 📋 Table of Contents

- [🔍 Overview](#overview)
- [✨ Features](#features)
- [🔧 Prerequisites](#prerequisites)
- [🚀 Installation](#installation)
- [📦 What Gets Installed](#what-gets-installed)
- [⚙️ Configuration](#configuration)
- [🔐 GPG Key Setup with 1Password](#gpg-key-setup-with-1password)
- [📂 Directory Structure](#directory-structure)
- [🛠️ Customizing](#customizing)
- [❓ Troubleshooting](#troubleshooting)
- [📄 License](#license)

## Overview

BootKit creates a consistent, reproducible developer environment, allowing you to declaratively define your toolset and configurations. Restore your complete environment on a new machine or keep multiple machines in sync with minimal effort.

## Features

- ✅ **Homebrew Integration**: Automated package installation via Brewfile
- ✅ **Dotfile Management**: Version-controlled configuration files via Dotdrop
- 🔐 **Secure Credentials**: GPG key import via 1Password CLI
- ⚡ **Shell Enhancement**: Zsh plugin management with zgenom
- 📦 **Reproducibility**: Consistent environment setup across multiple machines
- 🔄 **Idempotent**: Safely run multiple times without side effects
- 🧩 **Modular Design**: Ruby-based helper libraries for maintainability
- ⚙️ **Configurable**: YAML-based configuration for flexibility

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

BootKit uses YAML for configuration. A `bootkit.example.yml` file is provided as a template and automatically copied to `bootkit.yml` during installation:

```yaml
# 1Password Configuration
onepassword:
  vault: Dotfiles              # Name of your 1Password vault
  gpg_key_path: GPG Key/notes  # Path to your GPG key in 1Password

# GPG Configuration
gpg:
  key_id: ~                    # Optional: Specify your GPG key ID directly

# Logging Configuration
logging:
  level: info                  # Log level: debug, info, warn, error
```

You can edit the `bootkit.yml` file to customize your settings:

```bash
# Edit the configuration file
nano bootkit.yml
```

> **Important**: The `bootkit.yml` file may contain sensitive information and is automatically added to `.gitignore`. Never commit this file to version control.

### Homebrew Packages

Edit the `Brewfile` to customize which packages, casks, and App Store applications to install:

```ruby
# Example Brewfile entries
brew "git"
brew "node"
cask "visual-studio-code"
mas "Xcode", id: 497799835
```

### Dotfiles

Dotfiles are managed using [Dotdrop](https://github.com/deadc0de6/dotdrop), which provides powerful features like templating, encryption, and profile-based configuration.

The `config.yaml` file contains your Dotdrop configuration:

```yaml
# Configuration for handling sensitive files
variables:
  keyid: "{{@@ env['GPG_KEY_ID'] @@}}"  # Uses GPG key ID automatically extracted during installation
trans_install:
  _decrypt: "gpg -q --for-your-eyes-only--no-tty -d {0} > {1}"
trans_update:
  _encrypt: "gpg -q -r {{@@ keyid @@}} --armor --no-tty -o {1} -e {0}"

# Dotfile definitions
dotfiles:
  f_zshrc:
    src: zshrc       # File in dotfiles/ directory
    dst: ~/.zshrc    # Destination in your home directory
  f_ssh_config:
    src: ssh/config
    dst: ~/.ssh/config
    chmod: '600'     # Set specific permissions
    trans_install: _decrypt  # Use decryption during installation
    trans_update: _encrypt   # Use encryption when updating
```

#### Adding New Dotfiles

To add existing dotfiles to be managed by Dotdrop:

```bash
# Import a regular dotfile
dotdrop import ~/.some_dotfile

# Import and encrypt sensitive dotfiles
dotdrop import --transw=_encrypt --transr=_decrypt ~/.secret_file
```

#### Profiles

Dotfiles are organized by profiles in the `config.yaml` file, allowing different configurations for different machines.

## GPG Key Setup with 1Password

1. Export your private key:
   ```bash
   gpg --export-secret-keys --armor you@example.com
   ```

2. Save it to a 1Password secure note:
   - Vault: `Dotfiles` (or the value specified in your `bootkit.yml` file)
   - Title: `GPG Key` (or the path specified in your `bootkit.yml` file)
   - Store key in `notes` field

3. The installation script will import it automatically during setup.

4. Alternatively, you can specify your GPG key ID directly in the `bootkit.yml` file:
   ```yaml
   gpg:
     key_id: E7CFA32A  # Your GPG key ID
   ```

## Directory Structure

```
bootkit/
├── bin/                # Executable scripts
│   ├── install         # Main installation script
│   └── import_gpg      # GPG key import script
├── lib/                # Ruby libraries and modules
│   ├── bootkit_helpers.rb  # Common helper functions
│   └── import_gpg.rb   # GPG key import implementation
├── Brewfile            # Homebrew package definitions
├── bootkit.example.yml # Example configuration
├── bootkit.yml         # Your configuration (gitignored)
├── config.yaml         # Dotdrop configuration
└── dotfiles/           # Your dotfiles
    ├── zshrc           # Zsh configuration
    ├── gitconfig       # Git configuration
    └── ...             # Other dotfiles
```

## Customizing

The BootKit is designed to be easily customized:

1. **Adding new dotfiles**: Use Dotdrop's import command to add files:
   ```bash
   # Import a regular dotfile
   dotdrop import ~/.some_dotfile
   
   # Import and encrypt sensitive dotfiles
   dotdrop import --transw=_encrypt --transr=_decrypt ~/.secret_file
   ```

2. **Adding new packages**: Update the `Brewfile` with new packages

3. **Custom scripts**: Add any custom installation scripts to the `bin/` directory

## Troubleshooting

### Common Issues

- **GPG key import fails**: 
  - Ensure your 1Password note is properly formatted and the CLI has access
  - Check that your `bootkit.yml` file has the correct vault name and path
  - If specifying a GPG key ID directly, verify it's correct with `gpg --list-keys`

- **Ruby script errors**:
  - Ensure Ruby is installed: `ruby --version`
  - Check permissions on scripts: `chmod +x bin/*`

- **1Password CLI authentication issues**:
  - Verify 1Password CLI is installed: `op --version`
  - Ensure you're using the correct account details
  - Try signing in manually first: `op signin`

- **Homebrew installation errors**: 
  - Check internet connection and try running `bin/install` again
  - For permission issues: `sudo chown -R $(whoami) /usr/local/Homebrew`

- **Dotfile conflicts**: 
  - Backup and remove existing dotfiles if you encounter symlink errors

### Debugging

For more detailed debugging of the GPG key import process:

```bash
# Run the script with more verbose output
BOOTKIT_LOG_LEVEL=debug ./bin/import_gpg

# Check if your GPG key is properly imported
gpg --list-secret-keys

# Verify 1Password CLI can access your vault
op list items --vault="Dotfiles"
```

## License

This project is licensed under the MIT License - see the LICENSE file for details
