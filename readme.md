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

2. **Define a custom Git alias for working with the dotfiles**:

   ```bash
   alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
   ```

3. **Set the `dotfiles` repository to not show untracked files**:

   ```bash
   dotfiles config --local status.showUntrackedFiles no
   ```

4. **You're all set!** You can now use the `dotfiles` alias to manage your dotfiles.

## Usage

Once installed, managing your dotfiles is straightforward.
Use the following commands to interact with your dotfiles repository:

- **Track a new file**:

  ```bash
  dotfiles add .zshrc
  dotfiles commit -m "Add ZSH configuration"
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
  git clone --separate-git-dir=$HOME/.dotfiles https://github.com/<username>/dotfiles.git dotfiles-tmp
  rsync --recursive --verbose --exclude '.git' dotfiles-tmp/ $HOME/
  rm --recursive dotfiles-tmp
  ```

3. **Reinstall packages from `brew_packages.txt`**:

  If you've exported your Homebrew packages list previously with `brew leaves > brew_packages.txt`, you can reinstall them using this command:

  ```bash
  xargs brew install < brew_packages.txt
  ```

4. **Install directly other packages**:

For the tools installed directly (not via Homebrew), follow the instructions below:

1. **Bun**:
- Install Bun by running the following command:

  ```bash
  curl https://bun.sh/install | bash
  ```

2. **Golang**:
- Download and install Go from the official site:
  [Download Golang](https://go.dev/dl/) and follow the instructions for your operating system.

3. **Rust**:
- Install Rust via `rustup` (the recommended way to install Rust):

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

4. **Python via uv**:
- Install uv using the [official installation](https://docs.astral.sh/uv/getting-started/installation/) script:

  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```

## Included Configurations

This repository includes configuration files for:

- [Git](https://git-scm.com/)
- [Zsh shell](https://www.zsh.org/)
- [Starship prompt](https://starship.rs/)
- [WezTerm terminal](https://wezfurlong.org/wezterm/)
- [Homebrew package manager](https://brew.sh/)
- [Atuin shell history](https://atuin.sh) - A powerful, searchable shell history replacement.
- [Direnv](https://direnv.net) - A shell extension to manage environment variables depending on your working directory.
- [Topgrade](https://github.com/r-darwish/topgrade) - A command-line tool to upgrade all your dependencies and tools in one go.
- ...

**Update** custom configurations like the Git username and email, walk through the configurations and customize.

## Exporting Homebrew Packages

To export a list of the packages you explicitly installed (excluding dependencies), use the following command:

```bash
brew leaves > brew_packages.txt
```

This will create a `brew_packages.txt` file containing only the packages you requested to install, without including any dependencies.

## Unlicense

**TL;DR: Feel free to fork this repository and customize it for your own use!**

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to https://unlicense.org/.
