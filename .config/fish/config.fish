# ---
# Global settings
#
# Note: fish automatically reads ~/.config/fish/conf.d/*.fish on startup.
# ---

# Environment settings
set -gx CACHE $HOME/.cache
set -gx EDITOR hx
set -gx VISUAL zed --wait

# Disable telemetry. See https://consoledonottrack.com
set -gx DO_NOT_TRACK 1
set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1
set -gx STORYBOOK_DISABLE_TELEMETRY 1
set -gx AZURE_CORE_COLLECT_TELEMETRY 0

# Homebrew environment variables
set -gx HOMEBREW_BAT 1
set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400
fish_add_path /opt/homebrew/bin

# pnpm
set -gx PNPM_HOME /Users/marco/Library/pnpm
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# LMStudio CLI (lms)
set -gx PATH $PATH /Users/marco/.lmstudio/bin

# ---
# Interactive settings
# ---

if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_greeting

    # Abbreviations for aliases
    abbr --add brwe brew
    abbr --add calc eva
    abbr --add cls clear
    abbr --add cat bat
    abbr --add grep rg
    abbr --add find fd
    abbr --add up topgrade
    abbr --add now tz -q
    abbr --add ... ../../
    abbr --add lg lazygit

    # Folders listings
    abbr --add ls eza
    abbr --add l eza -a --icons --group-directories-first --git --git-repos
    abbr --add ll eza -a --icons --group-directories-first --git --git-repos -l --no-user --time-style=relative -X
    abbr --add tree eza -a --icons --group-directories-first --git --git-repos -T -L 3
    abbr --add dree eza -a --icons --group-directories-first --git --git-repos -T -L 3 --git-ignore

    # ---
    # Custom functions
    # ---

    # mkcd: make directory and change into it
    function mkcd
        if test (count $argv) -eq 0
            echo "Usage: mkcd [directory]"
            return 1
        end
        mkdir -p $argv[1]
        cd $argv[1]
    end

    # conf: edit configuration files
    function conf
        $VISUAL ~/.config \
            ~/.gitconfig
        src
    end

    # src: reload fish configuration
    function src
        source ~/.config/fish/config.fish
        echo "Configuration reloaded."
    end

    # dotfiles: manage dotfiles repository
    function dotfiles
        /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
    end

    # ---
    # Interactive tools
    # ---

    fzf --fish | source
    atuin init fish | source
    zoxide init fish | source

    # https://mise.jdx.dev/getting-started.html#activate-mise
    ~/.local/bin/mise activate fish | source

    # opencode
    fish_add_path /Users/marco/.opencode/bin

    # Only in Ghostty (and not in VSCode or Terminal)
    if test "$TERM_PROGRAM" = ghostty
        # Prompt
        function starship_transient_prompt_func
            starship module character
        end
        starship init fish | source
        enable_transience
        # System info
        macchina -s -m -p -D /
    end
else
    # Non-interactive session settings can go here

    # https://mise.jdx.dev/ide-integration.html#adding-shims-to-path-default-shell
    ~/.local/bin/mise activate fish --shims | source
end
