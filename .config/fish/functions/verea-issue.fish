function verea-issue
    argparse 'oc' 'cc' 'cx' 'pi' -- $argv
    or return

    if test -z "$argv[1]"
        echo "Usage: verea-issue [--oc|--cc|--cx|--pi] <issue-number-or-url>"
        return 1
    end

    set -l issue_number (string match -r '\d+' -- $argv[1] | tail -n1)
    if test -z "$issue_number"
        echo "Error: cannot parse issue number from \"$argv[1]\""
        return 1
    end

    set -l issue_title (gh issue view $issue_number --repo askverea/verea --json title --jq '.title')
    if test $status -ne 0
        echo "Error: issue #$issue_number not found (gh failed)"
        return 1
    end

    echo "Issue #$issue_number: $issue_title"

    set -l short_slug (_wt_slug "$issue_title")
    set -l branch_name "$issue_number-$short_slug"
    set -l clone_name "verea-$branch_name"
    set -l clone_dir "$HOME/Developer/askverea/$clone_name"

    echo "Directory: $clone_name"
    _wt_prepare https://github.com/askverea/verea.git "$clone_dir" "$branch_name" 1
    or return 1

    set -l prompt "Implement #$issue_number — $issue_title

URL: https://github.com/askverea/verea/issues/$issue_number
Branch: $branch_name"

    echo "────────────────────────────────────"
    echo "$prompt"
    echo "────────────────────────────────────"

    set -l agent
    if set -q _flag_oc; set agent oc
    else if set -q _flag_cc; set agent cc
    else if set -q _flag_cx; set agent cx
    else if set -q _flag_pi; set agent pi
    end

    _wt_launch "$agent" "$prompt" "$clone_dir"
end
