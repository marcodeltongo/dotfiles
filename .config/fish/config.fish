# ==========================================================
# Fish shell global settings • https://fishshell.com
# ==========================================================
# Note:
# ~/.config/fish/conf.d/*.fish read automatically on startup

# Disable greeting for all sessions
set -g fish_greeting

# Set default key bindings
set -g fish_key_bindings fish_default_key_bindings

# Environment settings
set -gx CACHE $HOME/.cache
set -gx EDITOR hx
set -gx VISUAL "zed --wait"

# Disable telemetry
set -gx DO_NOT_TRACK 1
set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1
set -gx STORYBOOK_DISABLE_TELEMETRY 1
set -gx AZURE_CORE_COLLECT_TELEMETRY 0

# Homebrew
set -gx HOMEBREW_BAT 1
set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400
fish_add_path /opt/homebrew/bin

# LMStudio CLI
fish_add_path $HOME/.lmstudio/bin

# ========================================
# Interactive settings
# ========================================

if status is-interactive
    # Abbreviations
    abbr --add brwe brew
    abbr --add calc eva
    abbr --add cat bat
    abbr --add grep rg
    abbr --add find fd
    abbr --add ... ../../
    abbr --add conf conf-func
    abbr --add src src-func

    # Directory listings (using eza)
    function ls
        eza -a --icons --group-directories-first $argv
    end
    function ll
        eza -a --icons --group-directories-first --git --git-repos --no-permissions --no-filesize --no-user --time-style=relative -l -X --all $argv
    end
    function la
        eza -a --icons --group-directories-first --git --git-repos --header --time-style=relative -l -X --all --total-size $argv
    end
    function tree
        eza -a --icons --group-directories-first -T -L 3 $argv
    end
    function dree
        eza -a --icons --group-directories-first -T -L 3 --git-ignore $argv
    end

    # Upgrade packages
    function up
        topgrade --cleanup
    end

    # Custom functions
    function mkcd
        if test (count $argv) -eq 0
            echo "Usage: mkcd [directory]"
            return 1
        end
        mkdir -p $argv[1]
        cd $argv[1]
    end

    function conf-func
        $VISUAL ~/.config ~/.gitconfig
        src-func
    end

    function src-func
        source ~/.config/fish/config.fish
        echo "Configuration reloaded."
    end

    function dotfiles
        command git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
    end

    # Tools
    fzf --fish | source
    zoxide init fish | source
    ~/.local/bin/mise activate fish | source
    wt config shell init fish | source
    fish_add_path $HOME/.opencode/bin
    starship init fish | source

    # Ghostty-specific
    if test "$TERM_PROGRAM" = ghostty
        macchina -s -m -p -D /
    end
else
    ~/.local/bin/mise activate fish --shims | source
end

# Added by Antigravity
fish_add_path /Users/marco/.antigravity/antigravity/bin
