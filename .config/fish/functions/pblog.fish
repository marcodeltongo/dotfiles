function pblog
    if test (count $argv) -eq 0
        echo "Usage: pblog <command>"
        return 1
    end

    set -l command $argv[1]
    set -l hash (echo "$command" | md5 -q)

    eval "$command" 2>&1 | tee /tmp/$hash.log
    pbcopy < /tmp/$hash.log
end
