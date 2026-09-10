#!/usr/bin/env bash
# Contract for gh-foreign-repo-guard.py.
#
# The guard is fail-safe by design: anything it cannot prove belongs to an
# allowed owner is denied. That makes its failures quiet, because a guard that
# denies too much looks exactly like a guard that is working. So every case here
# states the verdict it must produce, and the allow cases matter as much as the
# deny ones: without them, a guard that denied everything would pass its suite.
#
# Needs network and an authenticated gh: the node-id cases resolve real ids
# against GitHub, which is the whole point of that code path. A machine without
# either will see them fail closed, which is the correct behaviour and also
# indistinguishable from a regression, so run this online.
GUARD="${GUARD:-$HOME/.claude/hooks/gh-foreign-repo-guard.py}"

# askverea/verea PR #1784, a thread that exists. Ids are stable.
OURS="PRRT_kwDOQwqeO86hQaDI"
# torvalds/linux, the repository node itself.
THEIRS="MDEwOlJlcG9zaXRvcnkyMzI1Mjk4"

failures=0

check() {
  local want="$1" name="$2" cmd="$3" payload out got
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]},"cwd":"/tmp"}))' "$cmd")"
  out="$(printf '%s' "$payload" | python3 "$GUARD")"
  case "$out" in
    *'"deny"'*) got=deny ;;
    "") got=allow ;;
    *) got="unexpected" ;;
  esac
  if [ "$got" = "$want" ]; then
    printf 'ok    %-50s %s\n' "$name" "$got"
  else
    printf 'FAIL  %-50s want=%s got=%s\n' "$name" "$want" "$got"
    failures=$((failures + 1))
  fi
}

# A mutation addressed by an opaque node id names no owner in its text. The
# guard resolves the id against GitHub rather than guessing, so these two cases
# are the ones that prove it asks instead of assuming.
check allow "mutation on a node id that resolves to us" \
  "gh api graphql -f query='mutation{resolveReviewThread(input:{threadId:\"$OURS\"}){thread{isResolved}}}'"
check deny "mutation on a node id that resolves to a third party" \
  "gh api graphql -f query='mutation{createIssue(input:{repositoryId:\"$THEIRS\",title:\"x\"}){issue{id}}}'"

# Unprovable stays denied. Each of these is a different way to be unprovable,
# and all three must land on the same side of the line as before node-id
# resolution existed.
check deny "mutation on a node id that resolves to nothing" \
  "gh api graphql -f query='mutation{resolveReviewThread(input:{threadId:\"PRRT_kwDOAAAAAA6hQaDI\"}){thread{isResolved}}}'"
check deny "mutation carrying no id at all" \
  "gh api graphql -f query='mutation{addStar(input:{starrableId:\"\"}){clientMutationId}}'"
check deny "mutation naming a third-party owner in the query" \
  "gh api graphql -f query='mutation{createIssue(input:{repositoryId:\"x\"}){issue{id}}} # owner: torvalds'"

# The paths that carry everyday work must not have moved.
check allow "write on an allowed repo" \
  "gh issue comment 1549 --repo askverea/verea --body hello"
check allow "read on a third-party repo" \
  "gh pr view 123 --repo torvalds/linux"
check deny "write on a third-party repo" \
  "gh issue create --repo torvalds/linux --title x --body y"
check deny "write on a third-party repo addressed by URL" \
  "gh pr comment https://github.com/torvalds/linux/pull/1 --body x"
check deny "unparseable gh command" \
  "gh issue create --repo askverea/verea --body 'unbalanced"

if [ "$failures" -eq 0 ]; then
  echo "gh-foreign-repo-guard: PASS (node-id resolution, fail-safe defaults, allowlist, read/write split)"
else
  echo "gh-foreign-repo-guard: $failures FAILED"
  exit 1
fi
