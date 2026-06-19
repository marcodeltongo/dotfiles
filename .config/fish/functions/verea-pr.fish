function verea-pr
    argparse 'oc' 'cc' 'cx' 'pi' -- $argv
    or return

    if test -z "$argv[1]"
        echo "Usage: verea-pr [--oc|--cc|--cx|--pi] <pr-number-or-url>"
        return 1
    end

    set -l pr_number (string match -r '\d+' -- $argv[1] | tail -n1)
    if test -z "$pr_number"
        echo "Error: cannot parse PR number from \"$argv[1]\""
        return 1
    end

    set -l pr_info (gh pr view $pr_number --repo askverea/verea --json title,headRefName)
    if test $status -ne 0
        echo "Error: PR #$pr_number not found (gh failed)"
        return 1
    end

    set -l pr_title (echo $pr_info | jq -r '.title')
    set -l pr_branch (echo $pr_info | jq -r '.headRefName')

    echo "PR #$pr_number: $pr_title"
    echo "Branch: $pr_branch"

    # Sanitize branch into a safe directory name (not just '/').
    set -l clone_name "verea-"(string replace -r -a '[^a-z0-9._-]' '-' -- (string lower "$pr_branch") | string replace -r -a -- '-+' '-' | string trim --chars='-')
    set -l clone_dir "$HOME/Developer/askverea/$clone_name"

    echo "Directory: $clone_name"
    _wt_prepare https://github.com/askverea/verea.git "$clone_dir" "$pr_branch" 0
    or return 1

    set -l prompt "Review and continue PR #$pr_number — $pr_title

URL: https://github.com/askverea/verea/pull/$pr_number
Branch: $pr_branch"

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
