function verea-ci
    if test -z "$argv[1]"
        echo "Usage: verea-ci <pr-number-or-url>"
        return 1
    end

    set -l pr_number (string match -r '\d+' -- $argv[1] | tail -n1)
    if test -z "$pr_number"
        echo "Error: cannot parse PR number from \"$argv[1]\""
        return 1
    end

    gh pr update-branch $pr_number --repo askverea/verea
    or return 1

    sleep 30
    gh pr checks $pr_number --repo askverea/verea --watch --fail-fast
end
