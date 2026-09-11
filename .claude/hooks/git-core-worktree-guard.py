#!/usr/bin/env python3
"""PreToolUse gate: refuse a persistent git config write of core.worktree.

A core.worktree in a repository's shared config redirects every git command in
the main checkout into the directory it names. On 2026-09-10 one landed in
verea's shared .git/config from a `git config` run without `--worktree`, and the
main checkout wrote its own uncommitted work into a sibling worktree and removed
a committed file from it (askverea/verea#1796). Nothing in git can refuse the
write: `extensions.worktreeConfig` does not stop an unscoped `git config`, and a
read-only config breaks legitimate writes. So this refuses it where agent
sessions issue it.

Refused: any persistent write whose key is core.worktree, at any scope, in
either syntax (`git config core.worktree X`, `--add`, `--replace-all`, and
`git config set ...` from git 2.46 on). `--worktree` is not a way out: a
core.worktree in a worktree's own config.worktree redirects that worktree
instead, which is the same failure one directory over.

Let through: reads (`--get`, `--get-all`, `--show-origin`, `get`, `list`, and a
bare `git config core.worktree`), because the repository's detector tells
people to run exactly those; and unsets (`--unset`, `--unset-all`, `unset`),
because that is the remedy.

Limits, stated so they are not mistaken for coverage: `git -c core.worktree=X
<cmd>` and `GIT_WORK_TREE=X` act on a single command and persist nothing, so
they are out of scope; `git config --edit` cannot be read from the command
text; a key assembled at runtime from variables is invisible to a text guard. It covers agent sessions only. The primary measure is the warning in
askverea/verea's scripts/worktree-ports.sh, which fires for anyone.

`segments()` is a copy of the one in gh-foreign-repo-guard.py, not an import:
each guard stays self-contained, so a change to one cannot disable the other.
"""

import json
import re
import shlex
import sys

KEY = "core.worktree"

GIT_BIN = re.compile(r"(?:^|/)git$")
SHELL_BIN = re.compile(r"(?:^|/)(?:ba|z|da|fi)?sh$")
LAUNCHERS = {"command", "env", "time", "nice", "builtin", "exec"}
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
OPERATOR_CHARS = set("&|;()<>")

# git's own options that take a separate value, so the value is never read as
# the subcommand while scanning for `config`.
GIT_OPTS_WITH_VALUE = {
    "-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path",
    "--super-prefix", "--config-env",
}
# `git config` options that take a separate value, so it is never read as the key.
CONFIG_OPTS_WITH_VALUE = {"-f", "--file", "--blob", "--type", "--default", "--comment", "--value"}

READ_FLAGS = {
    "--get", "--get-all", "--get-regexp", "--get-urlmatch", "-l", "--list",
    "--get-color", "--get-colorbool",
}
UNSET_FLAGS = {"--unset", "--unset-all", "--remove-section"}
WRITE_FLAGS = {"--add", "--replace-all"}
NEW_STYLE_NOT_WRITES = {"get", "list", "unset", "remove-section", "rename-section", "edit"}

DENY = (
    "Blocked: this persists core.worktree in a git config. In a repository with "
    "linked worktrees, a core.worktree in the shared config makes every git "
    "command in the main checkout read and write the directory it names instead "
    "of its own; on 2026-09-10 that silently overwrote a sibling worktree in "
    "askverea/verea (#1796). `--worktree` is not a way out: set there, it "
    "redirects that worktree instead. There is no legitimate reason to set it in "
    "these repositories. Reading it (`git config --show-origin --get-all "
    "core.worktree`) and unsetting it (`git config --unset core.worktree`) are "
    "allowed. If you believe it genuinely needs setting, stop and ask Marco."
)
UNPARSEABLE = (
    "Blocked: this command mentions core.worktree and could not be parsed "
    "(unbalanced quoting), so the core.worktree guard cannot prove it is not a "
    "config write. Rewrite it as a simple command, or ask Marco to run it."
)


def segments(command):
    """Split a shell command into argv lists, one per simple command.

    Quoting is honoured. Raises ValueError when the quoting is unbalanced,
    which the caller treats as unprovable.
    """
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    lexer.commenters = ""
    found, current = [], []
    for token in lexer:
        if token and all(c in OPERATOR_CHARS for c in token):
            if current:
                found.append(current)
                current = []
        else:
            current.append(token)
    if current:
        found.append(current)
    return found


def emit_deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def strip_prefix(tokens):
    """Drop launchers and leading VAR=value assignments in any order."""
    while tokens and (tokens[0] in LAUNCHERS or ASSIGNMENT.match(tokens[0])):
        tokens = tokens[1:]
    return tokens


def config_args(tokens):
    """Arguments after `config` in a git invocation, or None if it is not one."""
    if not tokens or not GIT_BIN.search(tokens[0]):
        return None
    i = 1
    while i < len(tokens):
        tok = tokens[i]
        if tok in GIT_OPTS_WITH_VALUE:
            i += 2
            continue
        if tok.startswith("-"):
            i += 1
            continue
        return tokens[i + 1:] if tok == "config" else None
    return None


def positionals(args):
    out, i = [], 0
    while i < len(args):
        arg = args[i]
        if arg in CONFIG_OPTS_WITH_VALUE:
            i += 2
            continue
        if arg.startswith("-"):
            i += 1
            continue
        out.append(arg)
        i += 1
    return out


def writes_core_worktree(args):
    """True when these `git config` arguments persist a core.worktree value.

    Keys compare case-insensitively, as git's section and variable names do:
    Core.WorkTree is the same key.
    """
    if args and args[0] == "set":
        rest = positionals(args[1:])
        return bool(rest) and rest[0].lower() == KEY
    if args and args[0] in NEW_STYLE_NOT_WRITES:
        return False
    flags = {a.split("=", 1)[0] for a in args if a.startswith("-")}
    if flags & (READ_FLAGS | UNSET_FLAGS):
        return False
    rest = positionals(args)
    if not rest or rest[0].lower() != KEY:
        return False
    # `git config <key>` alone is an implicit read. A value, or an explicit
    # --add / --replace-all, makes it a write.
    return len(rest) >= 2 or bool(flags & WRITE_FLAGS)


def segment_writes(tokens, depth=0):
    tokens = strip_prefix(tokens)
    if not tokens:
        return False
    # `bash -c "git config ..."`: look inside, a few levels deep at most.
    if depth < 3 and SHELL_BIN.search(tokens[0]) and "-c" in tokens[1:3]:
        at = tokens.index("-c")
        if at + 1 < len(tokens):
            return any(segment_writes(t, depth + 1) for t in segments(tokens[at + 1]))
        return False
    args = config_args(tokens)
    return args is not None and writes_core_worktree(args)


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    command = (payload.get("tool_input") or {}).get("command") or ""
    if "config" not in command:
        sys.exit(0)
    try:
        hit = any(segment_writes(t) for t in segments(command))
    except ValueError:
        if KEY in command.lower():
            emit_deny(UNPARSEABLE)
        sys.exit(0)
    if hit:
        emit_deny(DENY)
    sys.exit(0)


if __name__ == "__main__":
    main()
