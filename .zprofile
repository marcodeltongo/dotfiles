# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/marco/.docker/bin"
# End of Docker Desktop section.

# This file is intentionally empty.
# All configuration merged into .zshrc for simplicity.
# See .zshrc for details.


# Added by Antigravity CLI installer
export PATH="/Users/marco/.local/bin:$PATH"

# --- Fix: keep Homebrew tools ahead of /usr/bin in non-interactive login
# shells (zsh -lc, used by codex exec / agents). /etc/zprofile runs
# path_helper which puts /usr/bin first, so `git` resolves to Apple's
# /usr/bin/git xcode_select shim; inside read-only sandboxes that shim
# falls back to spawning xcodebuild -find git (slow, ~1-2s, high CPU).
# NOTE: .zshrc is NOT read by non-interactive login shells.
export PATH="/opt/homebrew/bin:$PATH"
