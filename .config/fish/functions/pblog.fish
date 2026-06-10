function pblog
    if test (count $argv) -eq 0
        echo "Usage: pblog <command>"
        return 1
    end

    set -l command $argv[1]
    set -l hash

    # Generate filename-friendly hash from command
    # Replace special characters with hyphens, make lowercase
    set hash (echo "$command" | tr '[:upper:]' '[:lower:]' | tr ' /:_' '-' | tr -s '-' | sed 's/^-//;s/-$//')

    # Execute command with output redirection and copy to clipboard
    eval "$command" 2>&1 | tee /tmp/$hash.log | pbcopy
end
