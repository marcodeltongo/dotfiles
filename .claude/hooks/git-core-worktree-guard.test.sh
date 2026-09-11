#!/usr/bin/env bash
# Contract for git-core-worktree-guard.py.
#
# The guard refuses one narrow thing, a persistent write of core.worktree, and
# lets the rest of git through. A guard like that fails in two quiet ways: it
# misses a write, or it starts refusing the reads and unsets that are the very
# diagnosis and remedy for the problem it exists to prevent. Both directions are
# pinned here, and each case states the verdict it must produce.
#
# Hermetic: every case feeds a synthetic PreToolUse payload. No git runs.
GUARD="${GUARD:-$HOME/.claude/hooks/git-core-worktree-guard.py}"
# The interpreter the hook runs under in settings.json, not whichever python3
# is first on PATH: a suite that passes under a different interpreter proves
# nothing about the one that actually executes the guard.
PYTHON="${PYTHON:-/usr/bin/python3}"

failures=0

check() {
  local want="$1" name="$2" cmd="$3" payload out got
  payload="$("$PYTHON" -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]},"cwd":"/tmp"}))' "$cmd")"
  out="$(printf '%s' "$payload" | "$PYTHON" "$GUARD")"
  case "$out" in
    *'"deny"'*) got=deny ;;
    "") got=allow ;;
    *) got="unexpected" ;;
  esac
  if [ "$got" = "$want" ]; then
    printf 'ok    %-58s %s\n' "$name" "$got"
  else
    printf 'FAIL  %-58s want=%s got=%s\n' "$name" "$want" "$got"
    failures=$((failures + 1))
  fi
}

# The incident, and every other way to persist the same key.
check deny "unscoped write, the incident"            "git config core.worktree /some/sibling"
check deny "--local write"                            "git config --local core.worktree /x"
check deny "--global write"                           "git config --global core.worktree /x"
check deny "--worktree write (redirects that tree)"   "git config --worktree core.worktree /x"
check deny "--add"                                    "git config --add core.worktree /x"
check deny "--replace-all"                            "git config --replace-all core.worktree /x"
check deny "typed write"                              "git config --type=path core.worktree /x"
check deny "new syntax: set"                          "git config set core.worktree /x"
check deny "new syntax: set --worktree"               "git config set --worktree core.worktree /x"
check deny "key in mixed case"                        "git config Core.WorkTree /x"
check deny "git -C another path"                      "git -C /repo config core.worktree /x"
check deny "leading env assignment"                   "GIT_DIR=/r/.git git config core.worktree /x"
check deny "second command of a compound"             "cd /repo && git config core.worktree /x"
check deny "inside bash -c"                           "bash -c 'git config core.worktree /x'"
check deny "inside fish -c"                           "fish -c 'git config core.worktree /x'"
check deny "unparseable and mentions the key"         "git config core.worktree '/x"

# The diagnosis and the remedy must never be refused: the detector in
# scripts/worktree-ports.sh tells people to run the first of these.
check allow "diagnose: --show-origin --get-all"       "git config --show-origin --get-all core.worktree"
check allow "read: --get"                             "git config --get core.worktree"
check allow "read: bare key, no value"                "git config core.worktree"
check allow "read: new syntax get"                    "git config get core.worktree"
check allow "remedy: --unset"                         "git config --unset core.worktree"
check allow "remedy: --unset-all"                     "git config --unset-all core.worktree"
check allow "remedy: new syntax unset"                "git config unset core.worktree"

# Everything else stays untouched.
check allow "another key"                             "git config core.bare false"
check allow "unrelated git"                           "git status"
check allow "the key inside a string, not a command"  "echo 'git config core.worktree /x'"
check allow "grep for the key"                        "grep -rn core.worktree ."
check allow "unparseable, key not mentioned"          "git commit -m 'unbalanced"

# Stated limit, pinned so it cannot quietly become a claim: a per-command
# override persists nothing, and this guard does not pretend to cover it.
check allow "limit: git -c per-command override"      "git -c core.worktree=/x status"

if [ "$failures" -eq 0 ]; then
  echo "git-core-worktree-guard: PASS (writes refused at every scope and syntax, reads and unsets untouched)"
else
  echo "git-core-worktree-guard: $failures FAILED"
  exit 1
fi
