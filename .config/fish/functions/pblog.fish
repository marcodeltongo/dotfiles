function pblog
    if test (count $argv) -eq 0
        echo "Usage: pblog <command>"
        return 1
    end

    set -l hash (echo $argv | md5 -q)
    set -l log /tmp/$hash.log

    script -q $log $argv
    col -b < $log | pbcopy
end
