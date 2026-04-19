# Bootkit

A secure, reproducible developer environment bootstrapper for macOS.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey)]()

## Table of Contents

- [Quick Start](#quick-start)
- [Daily Use](#daily-use)
- [Configuration Files](#configuration-files)
- [Dotdrop Management](#dotdrop-management)
- [GPG Key Setup with 1Password](#gpg-key-setup-with-1password)
- [Directory Structure](#directory-structure)
- [Troubleshooting](#troubleshooting)
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

```bash
git clone <your-bootkit-repo> ~/BootKit
cd ~/BootKit
./bin/install
```

`./bin/install` installs Homebrew packages, imports your GPG key from 1Password, deploys dotfiles, and sets up Zsh plugins. It's idempotent — safe to run multiple times.

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
onepassword:
  vault: Dotfiles
  gpg_key_path: GPG Key/notes
gpg:
  key_id: ~               # optional — set if you want to skip auto-detection
dotdrop:
  profile: YOUR-HOSTNAME
```

### `config.yaml`
Dotdrop configuration. Maps dotfiles in `dotfiles/` to their destinations on disk. Also defines GPG encryption/decryption transformations for sensitive files.

### `Brewfile`
Defines all packages, casks, and fonts to install via Homebrew.

### `dotfiles/`
Your actual config files. Sensitive files (SSH keys, AWS credentials, GPG config, etc.) are stored GPG-encrypted.

## Dotdrop Management

BootKit uses [Dotdrop](https://github.com/deadc0de6/dotdrop) under the hood. The `bootkit` CLI wraps the common commands so you don't need to remember the flags.

### Under the hood (raw dotdrop commands)

If you need dotdrop directly:

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

BootKit retrieves your GPG private key from 1Password at install time.

1. Export your private key:
   ```bash
   gpg --export-secret-keys -a YOUR_KEY_ID > private.key
   ```

2. Save it to a 1Password Secure Note:
   - Vault: matches `onepassword.vault` in your `bootkit.yml`
   - Title/path: matches `onepassword.gpg_key_path`
   - Store the key in the `notes` field

## Directory Structure

```
BootKit/
├── bin/
│   ├── bootkit     # Daily-use CLI (diff, save, restore, add, list, install)
│   ├── init        # First-time setup wizard (destructive — wipes dotfiles/)
│   └── install     # Full machine setup orchestrator
├── lib/            # Ruby modules (Homebrew, GPG, dotdrop, 1Password, etc.)
├── dotfiles/       # Your config files (some GPG-encrypted)
├── Brewfile        # Homebrew packages and casks
├── config.yaml     # Dotdrop configuration
├── bootkit.yml     # Your personal config (gitignored)
└── bootkit.example.yml
```

## Troubleshooting

### `dotdrop compare` fails with "No pinentry" error

```
gpg: public key decryption failed: No pinentry
```

Restart the GPG agent:

```bash
gpgconf --kill gpg-agent && gpg-agent --daemon
```

This happens after updating GPG, pinentry-mac, or `~/.gnupg/gpg-agent.conf`.

## License

MIT — see LICENSE file.

## Acknowledgements

- [Homebrew](https://brew.sh/)
- [Dotdrop](https://github.com/deadc0de6/dotdrop)
- [zgenom](https://github.com/jandamm/zgenom)
- [GPG](https://gnupg.org/)
- [1Password CLI](https://1password.com/downloads/command-line/)
