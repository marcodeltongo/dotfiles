#!/usr/bin/env bash
# ==========================================================
# macOS system defaults for a developer setup
# Run once after a fresh install or when you want to reset.
# ==========================================================
# Usage: bash ~/scripts/macos-defaults.sh
# Some settings require a logout/restart to take effect.
# ==========================================================

set -euo pipefail

echo "Applying macOS defaults..."

# ── Keyboard ───────────────────────────────────────────────
# Fast key repeat (lower = faster; macOS default is 6)
defaults write NSGlobalDomain KeyRepeat -int 2
# Short delay before key repeat starts (lower = faster; macOS default is 68)
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Enable full keyboard access (tab through all controls)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
# Disable automatic capitalisation
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Disable smart quotes and dashes (annoying in code)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ── Trackpad ───────────────────────────────────────────────
# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# ── Finder ─────────────────────────────────────────────────
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show status bar and path bar
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Show ~/Library in Finder
chflags nohidden ~/Library

# ── Dock ───────────────────────────────────────────────────
# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true
# Remove the auto-hide delay
defaults write com.apple.dock autohide-delay -float 0
# Fast animation
defaults write com.apple.dock autohide-time-modifier -float 0.25
# Dock icon size
defaults write com.apple.dock tilesize -int 48
# Use scale effect (faster than genie)
defaults write com.apple.dock mineffect -string "scale"
# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false

# ── Screenshots ────────────────────────────────────────────
# Save to Downloads instead of Desktop
defaults write com.apple.screencapture location -string "$HOME/Downloads"
# Save as PNG
defaults write com.apple.screencapture type -string "png"
# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# ── TextEdit ───────────────────────────────────────────────
# Open plain text by default
defaults write com.apple.TextEdit RichText -int 0

# ── Activity Monitor ───────────────────────────────────────
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0
# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# ── Restart affected apps ──────────────────────────────────
for app in Finder Dock SystemUIServer; do
    killall "$app" &>/dev/null || true
done

echo "Done. Some settings require a logout or restart to take effect."
