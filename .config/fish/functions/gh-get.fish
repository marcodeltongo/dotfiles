function gh-get
    if test (count $argv) -eq 0
        echo "Usage: gh-get <owner/repo>"
        return 1
    end
    set repo $argv[1]
    set dest "$HOME/Developer/$repo"
    mkdir -p (dirname "$dest")
    gh repo clone "$repo" "$dest"
end
