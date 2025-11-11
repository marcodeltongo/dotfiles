if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_greeting

    # ---
    # Environment settings
    # ---

    set -gx CACHE $HOME/.cache
    set -gx EDITOR code

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

    # ---
    # Aliases and abbreviations
    # ---

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

    # ---
    # Custom functions
    # ---

    # git: show status if no arguments are given
    function git
        if test (count $argv) -eq 0
            command git status
        else
            command git $argv
        end
    end

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
        $EDITOR ~/.config \
                ~/.gitconfig
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
    # 3rd party tools
    # ---

    # Prompt
    function starship_transient_prompt_func
        starship module character
    end
    starship init fish | source
    enable_transience

    # zoxide
    zoxide init fish | source

    # fzf
    fzf --fish | source

    # Show system info only in Ghostty and not in VSCode terminal
    if test "$TERM_PROGRAM" = "ghostty"
        macchina -s -m -p -D '/'
    end
end
