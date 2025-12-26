# My Dotfiles

This repository contains my personal configuration files (dotfiles) used for setting up and managing my development environment on a Mac.
It uses Git bare repository management, as inspired by this [StreakyCobra comment on HN](https://news.ycombinator.com/item?id=11071754) and other community setups.

## Table of Contents

- [Setup](#first-setup)
- [Usage](#usage)
- [Replication](#replication-on-a-new-machine)
- [Configurations](#included-configurations)
- [Packages](#exporting-homebrew-packages)
- [License](#unlicense)

## First setup

To clone this repository and integrate the dotfiles into your system, follow these steps:

1. **Clone the repository as a bare repository**:

   ```bash
   git clone --bare https://github.com/your-username/dotfiles.git $HOME/.dotfiles
   ```

2. **Checkout the dotfiles contents into your home directory**:

   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout
   ```

   If you get conflicts, you may need to back up existing files first.

3. **Set the `dotfiles` repository to not show untracked files**:

   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config --local status.showUntrackedFiles no
   ```

4. **You're all set!** The `dotfiles` alias from your checked-out Fish config will now be available for managing your dotfiles.

## Usage

Once installed, managing your dotfiles is straightforward.
Use the following commands to interact with your dotfiles repository:

- **Track a new file**:

  ```bash
  dotfiles add config/fish/config.fish
  dotfiles commit -m "Add Fish configuration"
  dotfiles push
  ```

  The first time you push you will need:
  ```bash
  dotfiles push --set-upstream origin main
  ```

- **Edit or add your dotfiles in your home directory**:

  ```bash
  dotfiles add <file>
  dotfiles commit -m "Update configuration for <file>"
  dotfiles push
  ```

- **Check the status of your dotfiles**:

  ```bash
  dotfiles status
  ```

- **Pull the latest changes**:

  ```bash
  dotfiles pull
  ```

## Replication on a new machine

1. **Install Homebrew and Git** (if not already installed):

  If you haven't installed Homebrew or GIT yet, you can do so with the following command:

  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git
  ```

2. **Clone the dotfiles**:

  ```bash
  git clone --separate-git-dir=$HOME/.dotfiles git@github.com:<username>/dotfiles.git dotfiles-tmp
  rsync --recursive --verbose --exclude '.git' dotfiles-tmp/ $HOME/
  rm --recursive dotfiles-tmp
  ```

3. **Reinstall packages with Homebrew**:

  If you've exported your Homebrew packages lists, you can reinstall them using this command:

  ```bash
  xargs brew install < ~/.config/brew_formulas.txt
  xargs brew install --cask < ~/.config/brew_casks.txt
  ```

## Included Configurations

This repository includes configuration files for:

- [Git](https://git-scm.com/)
- [Fish](https://fishshell.com/)
- [Ghostty](https://ghostty.org/)
- [Starship](https://starship.rs/)
- [Homebrew](https://brew.sh/)
- [Topgrade](https://github.com/r-darwish/topgrade)
- [Mise-en-place](https://mise.jdx.dev/)

**Remember** to customize configurations like Git username and email after cloning.

## Exporting Homebrew Packages

To export a list of the packages you explicitly installed (excluding dependencies), use the following command:

```bash
brew leaves --installed-on-request > .config/brew_formulas.txt
brew list --cask > .config/brew_casks.txt
```

This will create two files containing only the packages you requested to install, without including any dependencies.

## Unlicense

**TL;DR: Feel free to fork this repository and customize it for your own use!**

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to https://unlicense.org/.
