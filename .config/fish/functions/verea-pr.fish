function verea-pr
    argparse 'oc' 'cc' -- $argv
    or return

    set -l pr_number $argv[1]

    if test -z "$pr_number"
        echo "Usage: verea-pr [--oc] [--cc] <pr-number>"
        return 1
    end

    set -l pr_info (gh pr view $pr_number --repo askverea/verea --json title,headRefName 2>/dev/null)

    if test -z "$pr_info"
        echo "Errore: PR #$pr_number non trovata"
        return 1
    end

    set -l pr_title (echo $pr_info | jq -r '.title')
    set -l pr_branch (echo $pr_info | jq -r '.headRefName')

    echo "PR #$pr_number: $pr_title"
    echo "Branch: $pr_branch"

    set -l clone_name "verea-$pr_branch"
    set -l clone_dir "$HOME/Developer/askverea/$clone_name"

    echo "Directory: $clone_name"
    git clone https://github.com/askverea/verea.git $clone_dir
    or return 1

    cd $clone_dir
    git checkout $pr_branch
    or return 1

    mise run setup
    or return 1

    set -l prompt "Review and continue PR #$pr_number — $pr_title

URL: https://github.com/askverea/verea/pull/$pr_number
Branch: $pr_branch"

    echo "────────────────────────────────────"
    echo "$prompt"
    echo "────────────────────────────────────"

    if set -q _flag_oc
        opencode --prompt "$prompt" "$clone_dir"
    end

    if set -q _flag_cc
        claude "$prompt"
    end
end
