# Bootkit

A secure, reproducible developer environment bootstrapper for macOS that sets up your system with essential tools and configurations.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey)]()

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Installation](#installation)
  - [For First-Time Users](#for-first-time-users-setting-up-your-own-bootkit)
  - [For Deploying to a New Machine](#for-deploying-to-a-new-machine-after-initial-setup)
- [Before You Start](#before-you-start)
  - [Understanding the Workflow](#understanding-the-workflow)
  - [What You Need Before Starting](#what-you-need-before-starting)
- [Configuration Files Explained](#configuration-files-explained)
- [What Gets Installed](#what-gets-installed)
- [Configuration](#configuration)
- [Dotdrop Management](#dotdrop-management)
- [GPG Key Setup with 1Password](#gpg-key-setup-with-1password)
- [Updating Your Setup](#updating-your-setup)
- [Directory Structure](#directory-structure)
- [Customizing](#customizing)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Overview

BootKit helps you set up a consistent development environment on macOS. It uses a declarative approach to define your tools and configurations, making it easy to restore your complete environment on a new machine or keep multiple machines in sync.

**This repository contains Andre's personal BootKit setup.** You can use it as a reference or starting point to create your own. Run `./bin/init` after cloning to make it yours - it will remove Andre's personal dotfiles and guide you through setting up your own configuration.

## Features

- **Homebrew Integration**: Installs packages from your Brewfile
- **Dotfile Management**: Manages configuration files with [Dotdrop](https://github.com/deadc0de6/dotdrop), allowing you to store your dotfiles once and deploy them across multiple machines with profile-based configurations
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

## Quick Start

For experienced developers who want the TL;DR:

```bash
# Clone this repo (it contains Andre's personal setup as a reference)
git clone https://github.com/andrebras/bootkit.git ~/bootkit
cd ~/bootkit

# Run the initialization wizard to make it yours
./bin/init

# Add your dotfiles to dotfiles/ directory, configure config.yaml and Brewfile
# Then deploy:
./bin/install
```

## Installation

### For First-Time Users (Setting Up Your Own BootKit)

This repository contains Andre's personal BootKit setup. To create your own:

```bash
# 1. Clone this repository
git clone https://github.com/andrebras/bootkit.git ~/bootkit
cd ~/bootkit

# 2. Run the initialization wizard
./bin/init
# This will:
#   - Remove Andre's personal dotfiles
#   - Ask you questions about your setup
#   - Generate bootkit.yml and config.yaml for you

# 3. Add your own dotfiles
cp ~/.zshrc dotfiles/zshrc
cp ~/.gitconfig dotfiles/gitconfig
# ... add more dotfiles as needed

# 4. Configure Dotdrop (config.yaml)
# Edit config.yaml to map your dotfiles to their destinations
# See: https://dotdrop.readthedocs.io/en/latest/

# 5. Customize your Brewfile
# Edit Brewfile to include packages you want

# 6. Run the installer
./bin/install

# 7. Commit to your own repository
git add .
git commit -m "Initialize my BootKit"
git remote set-url origin <your-repo-url>
git push
```

### For Deploying to a New Machine (After Initial Setup)

Once you have your own BootKit repository configured:

```bash
# Clone your BootKit repository
git clone <your-bootkit-repo> ~/bootkit
cd ~/bootkit

# Run the installer
./bin/install
```

## Before You Start

### Understanding the Workflow

BootKit supports two main workflows:

**Workflow 1: Initial Setup (First Time)**
You're setting up BootKit for the first time. You'll:
1. Clone this repository (contains Andre's setup as reference)
2. Run `./bin/init` to make it yours
3. Manually add your dotfiles to `dotfiles/` directory
4. Configure `config.yaml` to map your dotfiles
5. Customize your `Brewfile`
6. Push to your own Git repository

**Workflow 2: Deploy to New Machine (Ongoing Use)**
You already have your BootKit repository configured. You'll:
1. Clone your BootKit repo
2. Run `./bin/install`
3. Everything deploys automatically

### What You Need Before Starting

**For Initial Setup:**
- Your existing dotfiles scattered on your machine (`.zshrc`, `.gitconfig`, etc.)
- A 1Password account with your GPG key stored as a Secure Note
- Knowledge of which packages/apps you want installed

**For Deploying to a New Machine:**
- Your configured BootKit repository
- 1Password installed and signed in
- That's it! Everything else is automated

## Configuration Files Explained

BootKit uses several configuration files. Here's what each one does:

### `bootkit.yml` (Your Personal Config)
**Created by**: `./bin/init` (from your answers) or manually from `bootkit.example.yml`
**Purpose**: Tells BootKit where to find your 1Password vault, GPG keys, and which Dotdrop profile to use
**Security**: In `.gitignore` - NEVER commit this file
**Contains**:
- Your 1Password vault name
- Path to your GPG key in 1Password
- Your Dotdrop profile name (usually hostname)
- Logging preferences

### `bootkit.example.yml` (Template)
**Created by**: Included in this repo
**Purpose**: Example template showing what goes in `bootkit.yml`
**Action Required**: Reference only (you don't edit this directly)

### `config.yaml` (Dotdrop Configuration)
**Created by**: `./bin/init` (minimal template) or you customize it
**Purpose**: Maps your dotfiles to their destination on your system
**Contains**:
- **dotfiles**: List of configuration files (e.g., `f_zshrc`, `f_gitconfig`)
- **profiles**: Machine-specific configs (work laptop vs personal Mac)
- **trans_install/trans_update**: Encryption/decryption commands for sensitive files

**Example**: Maps `dotfiles/zshrc` → `~/.zshrc` when you run `dotdrop install`

### `Brewfile` (Package List)
**Created by**: You customize this
**Purpose**: Defines packages, applications, and Mac App Store apps to install
**Contains**:
```ruby
brew "git"              # CLI tools
cask "visual-studio-code"  # GUI apps
mas "1Password", id: 123   # Mac App Store apps
```

### `dotfiles/` Directory (Your Configuration Files)
**Created by**: `./bin/init` creates empty directory; you populate it
**Purpose**: Stores all your actual dotfiles
**Contains**: `.zshrc`, `.gitconfig`, `.vimrc`, SSH configs, etc.

### How They Work Together

```
                    ┌─────────────────┐
                    │  bootkit.yml    │
                    │  • 1Password    │
                    │  • Profile name │
                    └────────┬────────┘
                             │
                             ↓
    ┌────────────────────────────────────────┐
    │           ./bin/install                │
    │  1. Reads bootkit.yml                  │
    │  2. Gets GPG key from 1Password        │
    │  3. Installs packages from Brewfile    │
    │  4. Runs dotdrop with your profile     │
    └────────────────┬───────────────────────┘
                     │
                     ↓
            ┌────────────────┐
            │  config.yaml   │──────> Reads dotfiles/ and maps them
            │  (Dotdrop)     │        to your home directory
            └────────────────┘
                     │
                     ↓
            ┌────────────────┐
            │   dotfiles/    │──────> Your actual config files
            │   • zshrc      │        get installed to ~/
            │   • gitconfig  │
            └────────────────┘

            ┌────────────────┐
            │   Brewfile     │──────> Packages installed via Homebrew
            └────────────────┘
```

## What Gets Installed

When you run `./bin/install`, BootKit will:

- Install Homebrew (if not already installed)
- Install all packages defined in your `Brewfile`
- Retrieve and import your GPG key from 1Password
- Install zgenom for Zsh plugin management
- Deploy your dotfiles using Dotdrop (based on your profile in `config.yaml`)

## Configuration

### YAML Configuration

BootKit uses a YAML file (`bootkit.yml`) for configuration. This file is automatically generated when you run `./bin/init`, but you can also create it manually:

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

**Note**: If you're setting up BootKit for the first time, run `./bin/init` instead of creating this file manually. The wizard will generate it for you.

If you need to create it manually:

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

## Dotdrop Management

BootKit uses [Dotdrop](https://github.com/deadc0de6/dotdrop) to manage dotfiles. Files are stored in `dotfiles/` and mapped to their home directory destinations in `config.yaml`. Sensitive files (SSH keys, AWS credentials, GPG config, etc.) are GPG-encrypted at rest.

### Daily Commands

Use the `bootkit` CLI (available after `./bin/install`):

| Command | What it does |
|---|---|
| `bootkit diff` | See what's different between repo and machine |
| `bootkit diff ~/.vimrc` | Diff a single file |
| `bootkit save ~/.vimrc` | I edited on my machine → save to repo |
| `bootkit restore ~/.vimrc` | Repo version → push to my machine |
| `bootkit add ~/.newfile` | Start tracking a new file |
| `bootkit list` | Show all tracked files |

### Under the Hood (raw dotdrop commands)

If you need to use dotdrop directly, first export your profile and GPG key:

```sh
export GPG_KEY_ID=$(grep 'key_id:' bootkit.yml | awk '{print $2}')
PROFILE=$(ruby -ryaml -e "puts YAML.load_file('bootkit.yml').dig('dotdrop','profile')")
```

| `bootkit` command | dotdrop equivalent |
|---|---|
| `bootkit diff` | `dotdrop compare -p $PROFILE -c config.yaml` |
| `bootkit diff ~/.vimrc` | `dotdrop compare -p $PROFILE -c config.yaml -C ~/.vimrc` |
| `bootkit save ~/.vimrc` | `dotdrop update -f -p $PROFILE -c config.yaml ~/.vimrc` |
| `bootkit restore ~/.vimrc` | `dotdrop install -f -p $PROFILE -c config.yaml f_vimrc` |
| `bootkit add ~/.newfile` | `dotdrop import -p $PROFILE -c config.yaml ~/.newfile` |
| `bootkit list` | `dotdrop files -p $PROFILE -c config.yaml` |

→ [Full dotdrop documentation](https://dotdrop.readthedocs.io/en/latest/)

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

## Updating Your Setup

### Adding New Dotfiles

When you want to add a new dotfile to your BootKit:

```bash
# 1. Copy the dotfile to your dotfiles/ directory
cp ~/.newconfig dotfiles/newconfig

# 2. Update config.yaml to include the new file
# Add to the 'dotfiles:' section:
#   f_newconfig:
#     src: newconfig
#     dst: ~/.newconfig
# Add to your profile's 'dotfiles:' list:
#   - f_newconfig

# 3. Test the installation locally
dotdrop install

# 4. Commit and push changes
git add dotfiles/newconfig config.yaml
git commit -m "Add newconfig dotfile"
git push
```

### Adding New Packages

To add new packages to install on all your machines:

```bash
# 1. Edit Brewfile
nano Brewfile

# 2. Add your package
# brew "new-package"
# cask "new-application"

# 3. Install on current machine
brew bundle

# 4. Commit and push
git add Brewfile
git commit -m "Add new-package to Brewfile"
git push
```

### Syncing Changes to Another Machine

When you've updated your BootKit repo and want to sync to another machine:

```bash
# On the other machine
cd ~/bootkit

# Pull latest changes
git pull

# Run the installer to apply updates
./bin/install
```

The installer is idempotent, so it's safe to run multiple times. It will only install missing packages and update changed dotfiles.

### Keeping Your Dotfiles in Sync

If you've made changes to dotfiles on your local machine:

```bash
# See what's different between your repo and local files
dotdrop compare

# Update the repo with your local changes
dotdrop update

# Commit and push
git add dotfiles/
git commit -m "Update dotfiles"
git push
```

## Directory Structure

```
bootkit/
├── bin/                       # Executable scripts
│   ├── init                   # Initialization wizard for new users
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
3. Verify that you're signed in to 1Password (open the 1Password desktop app and ensure you're authenticated)

### Dotdrop Compare Failing with "No pinentry" Error

If `dotdrop compare` fails with errors like:

```
gpg: public key decryption failed: No pinentry
gpg: decryption failed: No pinentry
[ERR] install transformation "_decrypt" failed for <file>
```

**Root Cause**: The GPG agent is running with outdated configuration and cannot find the pinentry program needed to decrypt files.

**Solution**: Restart the GPG agent to reload the configuration:

```bash
gpgconf --kill gpg-agent && gpg-agent --daemon
```

This typically happens after:
- Updating your GPG or pinentry configuration
- Installing/updating pinentry-mac via Homebrew
- Modifying `~/.gnupg/gpg-agent.conf`

After restarting the agent, `dotdrop compare` should work correctly and prompt for your GPG passphrase when needed.

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
