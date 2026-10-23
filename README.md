# Bootkit

```
 ____              _   _  ___ _   
| __ )  ___   ___ | |_| |/ (_) |_ 
|  _ \ / _ \ / _ \| __| ' /| | __|
| |_) | (_) | (_) | |_| . \| | |_ 
|____/ \___/ \___/ \__|_|\_\_|\__|
```

A secure, reproducible developer environment bootstrapper for macOS.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey)]()

## Table of Contents

- [Quick Start](#quick-start)
- [Daily Use](#daily-use)
- [Configuration Files](#configuration-files)
- [Dotdrop Management](#dotdrop-management)
- [1Password Setup](#1password-setup)
- [Manual steps on a new machine](#manual-steps-on-a-new-machine)
- [Directory Structure](#directory-structure)
- [License](#license)

## Quick Start

### First-time setup (making it yours)

This repo contains André's personal setup. `./bin/init` **deletes all existing dotfiles** and resets the config — use it to start fresh with your own.

```bash
git clone https://github.com/andrebras/bootkit.git ~/BootKit
cd ~/BootKit
./bin/init          # ⚠️ destructive — wipes dotfiles/, resets config.yaml and bootkit.yml
```

After init:
1. Copy your dotfiles into `dotfiles/`
2. Map them in `config.yaml`
3. Customize `Brewfile`
4. Run `./bin/install`
5. Push to your own repo

### Deploying to a new machine

First install the 1Password app, sign in, and turn on its SSH agent (see [1Password Setup](#1password-setup)). Then:

```bash
git clone <your-bootkit-repo> ~/BootKit
cd ~/BootKit
./bin/install
```

`./bin/install` installs Homebrew packages, deploys dotfiles, and sets up Zsh plugins. It's idempotent — safe to run multiple times.

## Daily Use

After install, `bootkit` is available in your PATH (symlinked to `~/.local/bin/bootkit`).

| Command | What it does |
|---|---|
| `bootkit diff` | See what's different between repo and machine |
| `bootkit diff ~/.vimrc` | Diff a single file |
| `bootkit save ~/.vimrc` | I edited on my machine → save to repo |
| `bootkit restore ~/.vimrc` | Repo version → push to my machine |
| `bootkit add ~/.newfile` | Start tracking a new file |
| `bootkit list` | Show all tracked files |
| `bootkit install` | Full machine setup |

After saving changes, commit and push as usual:

```bash
git add dotfiles/
git commit -m "Update dotfiles"
git push
```

## Configuration Files

### `bootkit.yml`
Your personal runtime config. Created by `./bin/init`. **Never commit this file** — it's in `.gitignore`.

```yaml
logging:
  level: info
dotdrop:
  profile: YOUR-HOSTNAME
```

### `config.yaml`
Dotdrop configuration. Maps dotfiles in `dotfiles/` to their destinations on disk.

### `Brewfile`
Defines all packages, casks, and fonts to install via Homebrew.

### `dotfiles/`
Your actual config files, stored as plain text. No secrets are kept here: SSH private keys live in 1Password and are served by the 1Password SSH agent.

## Dotdrop Management

BootKit uses [Dotdrop](https://github.com/deadc0de6/dotdrop) under the hood. The `bootkit` CLI wraps the common commands so you don't need to remember the flags.

### Under the hood (raw dotdrop commands)

If you need dotdrop directly:

```sh
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

## 1Password Setup

BootKit keeps no secrets. SSH keys live in 1Password, and the 1Password SSH agent serves them for SSH logins and for signing Git commits.

1. Install the 1Password app (it is in the `Brewfile`) and sign in.
2. In 1Password, go to Settings → Developer and turn on **Use the SSH agent**.
3. Commits are signed with an SSH key from 1Password: `gitconfig` sets `gpg.format = ssh` and uses 1Password's `op-ssh-sign`, and `~/.ssh/allowed_signers` lets Git verify those signatures.

## Manual steps on a new machine

A few files are kept outside the repo on purpose and must be set up by hand:

1. **Private SSH hosts.** `~/.ssh/config` includes every file in `~/.ssh/config.d/`. Copy your host files there from a safe place; they are not tracked by BootKit.
2. **Machine-specific Git settings.** `~/.gitconfig` includes `~/.gitconfig.local`, which is not tracked. Create it for settings that only apply to one machine, for example background maintenance:
   ```bash
   git maintenance register --config-file ~/.gitconfig.local
   ```

## Directory Structure

```
BootKit/
├── bin/
│   ├── bootkit     # Daily-use CLI (diff, save, restore, add, list, install)
│   ├── init        # First-time setup wizard (destructive — wipes dotfiles/)
│   └── install     # Full machine setup orchestrator
├── lib/            # Ruby modules (Homebrew, dotdrop, Zgenom, etc.)
├── dotfiles/       # Your config files
├── Brewfile        # Homebrew packages and casks
├── config.yaml     # Dotdrop configuration
├── bootkit.yml     # Your personal config (gitignored)
└── bootkit.example.yml
```

## License

MIT — see LICENSE file.

## Acknowledgements

- [Homebrew](https://brew.sh/)
- [Dotdrop](https://github.com/deadc0de6/dotdrop)
- [zgenom](https://github.com/jandamm/zgenom)
- [1Password SSH agent](https://developer.1password.com/docs/ssh/)
