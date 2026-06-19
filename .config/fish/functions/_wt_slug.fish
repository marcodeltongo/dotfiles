function _wt_slug --argument title
    # Normalize a free-form title into a short kebab slug, dropping common
    # stop/boilerplate words and keeping the first 3 significant tokens.
    set -l cleaned (string replace -r -a '([a-z])([A-Z])' '$1-$2' -- "$title" \
        | string replace -r -a '[_/]' '-' \
        | string lower \
        | string replace -r -a '[^a-z0-9\s-]' '' \
        | string trim \
        | string replace -r -a '\s+' '-' \
        | string replace -r -a -- '-+' '-' \
        | string trim --chars='-')

    set -l stop '^(fix|feat|add|update|remove|change|improve|refactor|chore|docs|test|the|a|an|and|or|for|to|in|on|with|by|of|from|into|through|during|before|after|up|down|off|out|over|under|at|as|is|was|be|been|are|were|has|have|had|do|does|did|will|would|can|could|shall|should|may|might|no|not|non|only|just|than|then|also|very|some|any|all|each|every|both|few|more|most|other|such|about|like|between|without|via|per|get|task|adopt|feature|investigation|tests|di|injected|drop)$'

    set -l filtered (string split '-' -- "$cleaned" \
        | string match -rv "$stop" \
        | awk '!seen[$0]++' \
        | head -n3 \
        | string join '-')

    if test -n "$filtered"
        echo $filtered
    else
        string sub -l30 -- "$cleaned" | string trim --chars='-'
    end
end
