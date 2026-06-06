function verea-issue
    argparse 'oc' 'cc' -- $argv
    or return

    set -l issue_number $argv[1]

    if test -z "$issue_number"
        echo "Usage: verea-issue [--oc] [--cc] <issue-number>"
        return 1
    end

    set -l issue_title (gh issue view $issue_number --repo askverea/verea --json title --jq '.title' 2>/dev/null)

    if test -z "$issue_title"
        echo "Error: issue #$issue_number not found"
        return 1
    end

    echo "Issue #$issue_number: $issue_title"

    set -l short_slug (string replace -r -a '([a-z])([A-Z])' '$1-$2' -- "$issue_title" \
        | string replace -r -a '[_/]' '-' \
        | string lower \
        | string replace -r -a '[^a-z0-9\s-]' '' \
        | string trim \
        | string replace -r -a '\s+' '-' \
        | string replace -r -a -- '-+' '-' \
        | string trim --chars='-' \
        | string split '-' \
        | string match -rv '^(fix|feat|add|update|remove|change|improve|refactor|chore|docs|test|the|a|an|and|or|for|to|in|on|with|by|of|from|into|through|during|before|after|up|down|off|out|over|under|at|as|is|was|be|been|are|were|has|have|had|do|does|did|will|would|can|could|shall|should|may|might|no|not|non|only|just|than|then|also|very|some|any|all|each|every|both|few|more|most|other|such|into|about|like|between|without|via|per|get|task|adopt|feature|investigation|tests|di|injected|drop)$' \
        | awk '!seen[$0]++' \
        | head -n3 \
        | string join '-')

    if test -z "$short_slug"
        set -l fallback (string replace -r -a '([a-z])([A-Z])' '$1-$2' -- "$issue_title" | string replace -r -a '[_/]' '-' | string lower | string replace -r -a '[^a-z0-9\s-]' '' | string trim | string replace -r -a '\s+' '-' | string replace -r -a -- '-+' '-' | string trim --chars='-')
        set short_slug (string sub -l30 -- "$fallback" | string trim --chars='-')
    end

    set -l branch_name "$issue_number-$short_slug"
    set -l clone_name "verea-$branch_name"
    set -l clone_dir "$HOME/Developer/askverea/$clone_name"

    git clone https://github.com/askverea/verea.git $clone_dir
    or return 1

    cd $clone_dir
    git checkout -b "$branch_name"
    or return 1

    mise run setup
    or return 1

    set -l prompt "Implement #$issue_number — $issue_title

URL: https://github.com/askverea/verea/issues/$issue_number
Branch: $branch_name"

    echo "────────────────────────────────────"
    echo "$prompt"
    echo "────────────────────────────────────"

    if set -q _flag_oc
        opencode --agent plan --prompt "$prompt" "$clone_dir"
    end

    if set -q _flag_cc
        claude --agent plan --model opus --effort max "$prompt"
    end
end
