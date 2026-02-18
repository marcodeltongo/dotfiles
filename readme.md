# My Dotfiles

Personal configuration files for macOS, managed as a [Git bare repository](https://news.ycombinator.com/item?id=11071754).

## Table of Contents

- [Quick start](#quick-start)
- [Manual setup](#manual-setup)
- [Personalization](#personalization)
- [Usage](#usage)
- [Included configurations](#included-configurations)
- [Exporting Homebrew packages](#exporting-homebrew-packages)
- [License](#unlicense)

## Quick start

On a fresh Mac, run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/marcodeltongo/dotfiles/main/install.sh)"
```

This will install Homebrew, clone the dotfiles, install all packages (formulae + casks, including fonts), set up mise tools, and set Fish as the default shell.

After it completes, see [Personalization](#personalization) before making your first commit.

## Manual setup

If you prefer to set things up yourself:

1. **Clone as a bare repository**:

   ```bash
   git clone --bare https://github.com/marcodeltongo/dotfiles.git $HOME/.dotfiles
   ```

2. **Checkout the dotfiles into your home directory**:

   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout
   ```

   If there are conflicts, back up existing files first, then retry.

3. **Suppress untracked file noise**:

   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config --local status.showUntrackedFiles no
   ```

4. **Install Homebrew packages**:

   ```bash
   brew install $(cat ~/.config/brew_formulas.txt)
   brew install --cask $(cat ~/.config/brew_casks.txt)
   ```

5. **You're all set!** The `dotfiles` function from the Fish config is now available.

## Personalization

> **If you're forking or cloning these dotfiles**, update the following before making any commits.

### Git identity

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

### GPG commit signing

Commit and tag signing is **enabled by default**. GPG Suite is installed via the cask list.

To set it up:
1. Open GPG Suite, import or generate your key
2. Copy the key ID (the long hex string)
3. Tell git about it:

```bash
git config --global user.signingKey YOUR_KEY_ID
```

To **disable signing** temporarily (e.g. while setting up):

```bash
git config --global commit.gpgsign false
git config --global tag.gpgSign false
```

## Usage

The `dotfiles` function (defined in `config.fish`) is an alias for
`git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`.

**Track a new file**:
```bash
dotfiles add .config/something/config
dotfiles commit -m "Add something config"
dotfiles push
```

**Update an existing file**:
```bash
dotfiles add .gitconfig
dotfiles commit -m "Update git aliases"
dotfiles push
```

**Check status / pull / log**:
```bash
dotfiles status
dotfiles pull
dotfiles lo
```

## Included configurations

| Tool | Config path |
|---|---|
| [Fish](https://fishshell.com/) | `.config/fish/config.fish` |
| [Git](https://git-scm.com/) | `.gitconfig`, `.config/git/ignore` |
| [Ghostty](https://ghostty.org/) | `.config/ghostty/config` |
| [Starship](https://starship.rs/) | `.config/starship.toml` |
| [Helix](https://helix-editor.com/) | `.config/helix/config.toml` |
| [Zed](https://zed.dev/) | `.config/zed/settings.json` |
| [mise](https://mise.jdx.dev/) | `.config/mise/config.toml` |
| [Topgrade](https://github.com/topgrade-rs/topgrade) | `.config/topgrade.toml` |
| [gh](https://cli.github.com/) | `.config/gh/config.yml` |
| [gh-dash](https://github.com/dlvhdr/gh-dash) | `.config/gh-dash/config.yml` |
| [Homebrew](https://brew.sh/) | `.config/brew_formulas.txt`, `.config/brew_casks.txt` |

## Exporting Homebrew packages

To update the package lists after installing something new:

```bash
brew leaves --installed-on-request > ~/.config/brew_formulas.txt
brew list --cask > ~/.config/brew_casks.txt
```

This captures only the packages you explicitly requested, without dependencies.

## Unlicense

**TL;DR: Feel free to fork and customize!**

This is free and unencumbered software released into the public domain. Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, for any purpose, commercial or non-commercial, and by any means.

For more information, please refer to <https://unlicense.org/>.
