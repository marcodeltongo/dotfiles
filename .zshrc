# ZSH Configuration

# Enable zsh profiling if enabled (e.g. in .zshenv)
if [[ -n $ZPROF ]]; then
    zmodload zsh/zprof
fi

# Basic Setup
# -----------
autoload -U colors && colors
autoload -U zmv
setopt extendedglob  # Enable extended globbing features

# Directory Navigation
# --------------------
setopt auto_pushd        # Automatically push old directory onto directory stack
setopt pushd_ignore_dups # Don't push multiple copies of the same directory onto the directory stack
setopt pushd_silent      # Don't print the directory stack after pushd or popd

# Command Line Editing
# --------------------
# bindkey -v  # Use VIM key bindings
# bindkey -e  # Use Emacs key bindings

# Key Bindings
# ------------
# bindkey "^[[3~" delete-char                # Delete: Delete character under cursor
# bindkey '^[3;5~' delete-char               # Ctrl + Delete: Delete character under cursor

# Environment Setup
# -----------------
export LANG="en_US.UTF-8"
export PATH="$HOME/.local/bin:$PATH"
export CACHE="$HOME/.cache"

# ZSH Features
# ------------
setopt autocd            # Change to a directory just by typing its name
setopt correct           # Try to correct the spelling of commands
setopt correctall        # Try to correct the spelling of all arguments in a line
setopt interactivecomments  # Allow comments in interactive shells
setopt magicequalsubst   # Enable filename expansion for arguments of the form 'anything=expression'
setopt nonomatch         # If a pattern for filename generation has no matches, leave it unchanged
setopt notify            # Report the status of background jobs immediately
setopt numericglobsort   # Sort filenames numerically when it makes sense
setopt promptsubst       # Enable parameter expansion, command substitution and arithmetic expansion in prompts

# History Configuration
# ---------------------
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt appendhistory     # Append history to the history file (no overwriting)
setopt histignorealldups # Ignore duplicates when adding lines to the history list
setopt incappendhistory  # Append to history file immediately, not when shell exits
setopt sharehistory      # Share history between all sessions

# Homebrew
# --------
export HOMEBREW_BAT=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_AUTO_UPDATE_SECS=86400
eval "$(/opt/homebrew/bin/brew shellenv)"
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# Completions
# -----------
autoload -Uz compinit && compinit
source <(fzf --zsh)
source <(delta --generate-completion zsh)
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Plugins
# -------
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Default Editor
# --------------
export EDITOR="zed --wait"
export EDIT="zed"

# Modern Alternatives
# -------------------
alias cat='bat --theme="1337"'
alias df='duf'                  # Better disk usage/free utility
alias du='dust'                 # More intuitive disk usage analyzer
alias find='fd'                 # User-friendly alternative to find
alias grep='rg'                 # Faster alternative to grep
alias ls='eza'                  # Modern alternative to ls
alias md='glow'                 # Markdown reader
alias mon='macmon'              # Mac monitor
alias nano='ox'                 # Faster alternative to nano
alias ping='gping'              # Ping with a graph
alias ps='procs'                # Modern replacement for ps
alias sed='sd'                  # Intuitive find & replace CLI
alias top='btop'                # Resource monitor, alternative to top
alias vi='nvim'                 # Neovim

# Aliases & shortcuts
# -------
alias l='eza -a --icons --group-directories-first --git --git-repos'
alias ll='l -l --no-user --time-style=relative -X'
alias ...='../..'
alias tree='l -T -L 3'
alias up='topgrade'             # Upgrade macOS and Homebrew
alias cl='clear'                # Clear terminal

# Alias that runs `git status` if no additional arguments are provided
git() {
    if [ $# -eq 0 ]; then
        command git status
    else
        command git "$@"
    fi
}

# Aliases for common mistypes
# ---------------------------
alias brwe='brew'
alias golang='go'
alias rust='cargo'

# Dotfiles and configuration on Git
# ---------------------------------
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Custom Functions
# ----------------
if [ -d "$HOME/.config/zsh/functions/" ]; then
    for func in "$HOME"/.config/zsh/functions/*; do
        source "$func"
    done
fi

# Environment
# -----------

# https://consoledonottrack.com/
export DO_NOT_TRACK=1
export AZURE_CORE_COLLECT_TELEMETRY=0
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Development
export DEV=$HOME/Developer
eval "$(direnv hook zsh)"

# Rust
export CARGO_HOME=$CACHE/cargo
export RUSTUP_HOME=$CACHE/rustup
export PATH="$CARGO_HOME/bin:$PATH"
. "$CACHE/cargo/env"

# Golang
export GOPATH=$CACHE/go
export GOROOT=/usr/local/go
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# Python via UV
# https://docs.astral.sh/uv/
eval "$(uv generate-shell-completion zsh)"

# Node via HomeBrew
export NODE_ENV=development

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
alias bunfig="$EDIT ~/.config/.bunfig.toml"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# External tools for interactive shells
# --------------------------
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"

# bun completions
[ -s "/Users/marcodeltongo/.bun/_bun" ] && source "/Users/marcodeltongo/.bun/_bun"

# Conditional profiling (set in )
if [[ -n $ZPROF ]]; then
    zprof
fi
