# ========================================
# Zsh configuration for agent compatibility
# ========================================
# Primary shell: fish (~/.config/fish/config.fish)
# This file provides same tool availability for zsh-spawned agents

# --- Login/Non-interactive ---

# Homebrew shellenv
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(SHELL=/bin/zsh /opt/homebrew/bin/brew shellenv)"
fi

# Environment variables
export CACHE="$HOME/.cache"
export EDITOR="hx"
export VISUAL="zed --wait"

# Telemetry opt-outs
export DO_NOT_TRACK=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export STORYBOOK_DISABLE_TELEMETRY=1
export AZURE_CORE_COLLECT_TELEMETRY=0

# Homebrew behavior
export HOMEBREW_BAT=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_AUTO_UPDATE_SECS=86400

# PATH entries
typeset -U path
path=(
  "$HOME/.opencode/bin"
  "$HOME/.lmstudio/bin"
  $path
)
export PATH

# --- Interactive ---

if [[ -o interactive ]]; then
  setopt no_beep

  # Tool initializations (only when attached to TTY)
  if [[ -t 0 && -t 1 ]]; then
    command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
    command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
    command -v wt >/dev/null 2>&1 && eval "$(wt config shell init zsh)"
    [[ -x "$HOME/.local/bin/mise" ]] && eval "$($HOME/.local/bin/mise activate zsh)"
  fi
fi

# Mise shims for non-interactive sessions
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$($HOME/.local/bin/mise activate zsh --shims)"
fi
