function verea-issue
    set -l issue_number $argv[1]

    if test -z "$issue_number"
        echo "Usage: verea-issue <issue-number>"
        return 1
    end

    set -l issue_title (gh issue view $issue_number --repo askverea/verea --json title --jq '.title' 2>/dev/null)

    if test -z "$issue_title"
        echo "Errore: issue #$issue_number non trovato"
        return 1
    end

    echo "Issue #$issue_number: $issue_title"

    set -l branch_name (claude -p \
        "Given this GitHub issue title, output a branch name slug: 1 word ideally, 2 max, lowercase, hyphens only, no prefixes. Reply with ONLY the slug, nothing else.\n\nIssue: $issue_title" \
        --model claude-haiku-4-5-20251001 2>/dev/null \
        | tr '[:upper:]' '[:lower:]' \
        | tr -cs 'a-z0-9-' '-' \
        | string trim --chars='-')

    if test -z "$branch_name"
        echo "Errore: impossibile generare il nome branch"
        return 1
    end

    set -l clone_name "verea-$branch_name"
    set -l clone_dir "$HOME/Developer/askverea/$clone_name"

    echo "Branch: $clone_name"
    git clone https://github.com/askverea/verea.git $clone_dir
    or return 1

    cd $clone_dir
    mise run setup
    or return 1

    claude
end
