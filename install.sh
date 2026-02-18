#!/usr/bin/env bash
# ==========================================================
# macOS dotfiles bootstrap
# https://github.com/marcodeltongo/dotfiles
# ==========================================================
set -euo pipefail

DOTFILES_REPO="https://github.com/marcodeltongo/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# ── Helpers ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

step() { echo -e "\n${BLUE}${BOLD}==> $1${NC}"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
fail() { echo -e "${RED}✖${NC} $1"; exit 1; }

dotfiles() { git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"; }

# ── Guard ──────────────────────────────────────────────────
[[ "$(uname)" == "Darwin" ]] || fail "This script is for macOS only."

# ── 1. Homebrew ────────────────────────────────────────────
step "Homebrew"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew installed"
else
  ok "Already installed ($(brew --version | head -1))"
fi

# ── 2. Git ─────────────────────────────────────────────────
step "Git"
command -v git &>/dev/null || brew install git
ok "$(git --version)"

# ── 3. Clone dotfiles ──────────────────────────────────────
step "Dotfiles"
if [[ ! -d "$DOTFILES_DIR" ]]; then
  git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
  ok "Cloned to $DOTFILES_DIR"
else
  ok "Already cloned at $DOTFILES_DIR"
fi

dotfiles config --local status.showUntrackedFiles no

step "Checkout"
if ! dotfiles checkout 2>/dev/null; then
  warn "Conflicts found — backing up existing files to ~/.dotfiles-backup/"
  mkdir -p "$HOME/.dotfiles-backup"
  dotfiles checkout 2>&1 \
    | grep -E "^\s+\." \
    | awk '{print $1}' \
    | while read -r f; do
        mkdir -p "$HOME/.dotfiles-backup/$(dirname "$f")"
        mv "$HOME/$f" "$HOME/.dotfiles-backup/$f"
      done
  dotfiles checkout
  ok "Checked out (conflicts backed up to ~/.dotfiles-backup/)"
else
  ok "Checked out cleanly"
fi

# SSH sockets dir required by ControlMaster in ~/.ssh/config
mkdir -p "$HOME/.ssh/sockets" && chmod 700 "$HOME/.ssh/sockets"

# ── 4. Homebrew packages ───────────────────────────────────
step "Homebrew taps"
brew tap grdl/tap
brew tap homebrew-ffmpeg/ffmpeg
ok "Taps added"

step "Homebrew packages"
FORMULAS="$HOME/.config/brew_formulas.txt"
CASKS="$HOME/.config/brew_casks.txt"

if [[ -f "$FORMULAS" ]]; then
  grep -v '^\s*$' "$FORMULAS" | xargs brew install
  ok "Formulae installed"
else
  warn "brew_formulas.txt not found, skipping"
fi

if [[ -f "$CASKS" ]]; then
  grep -v '^\s*$' "$CASKS" | xargs brew install --cask
  ok "Casks installed"
else
  warn "brew_casks.txt not found, skipping"
fi

# ── 5. mise ────────────────────────────────────────────────
step "mise"
if ! command -v mise &>/dev/null; then
  brew install mise
  ok "mise installed"
else
  ok "mise already installed"
fi
mise install
ok "mise tools installed"

# ── 6. Fish as default shell ───────────────────────────────
step "Fish shell"
FISH_PATH="/opt/homebrew/bin/fish"
if [[ -x "$FISH_PATH" ]]; then
  if ! grep -qF "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    ok "Added fish to /etc/shells"
  fi
  if [[ "$SHELL" != "$FISH_PATH" ]]; then
    chsh -s "$FISH_PATH"
    ok "Default shell changed to fish"
  else
    ok "Fish is already the default shell"
  fi
else
  warn "Fish not found at $FISH_PATH — skipping shell change"
fi

# ── 7. gh auth ─────────────────────────────────────────────
step "GitHub CLI"
if ! gh auth status &>/dev/null; then
  warn "Not authenticated — run: gh auth login"
else
  ok "Already authenticated ($(gh auth status 2>&1 | grep 'Logged in' | head -1 | xargs))"
fi

# ── 8. macOS defaults ──────────────────────────────────────
step "macOS defaults"
if [[ -x "$HOME/scripts/macos-defaults.sh" ]]; then
  bash "$HOME/scripts/macos-defaults.sh"
else
  warn "scripts/macos-defaults.sh not found, skipping"
fi

# ── Done ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC} Open a new terminal to start using Fish."
echo ""
echo -e "${YELLOW}${BOLD}Before your first commit, personalize git:${NC}"
echo "  git config --global user.name  \"Your Name\""
echo "  git config --global user.email \"you@example.com\""
echo ""
echo -e "  Commit signing is ${BOLD}enabled${NC}. GPG Suite was installed via cask."
echo "  Import or create your key, then:"
echo "  git config --global user.signingKey YOUR_KEY_ID"
echo ""
echo "  Or disable signing temporarily:"
echo "  git config --global commit.gpgsign false"
