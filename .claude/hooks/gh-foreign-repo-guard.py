#!/usr/bin/env python3
"""PreToolUse gate: refuse public GitHub writes to repos outside the owner allowlist.

Opening an issue, discussion, PR or comment on a third-party repo publishes
content under Marco's account, on a thread he did not choose to start and will
not follow. Drafting such a report is fine; publishing it is his call.

Fail-safe by default: on a repo outside the allowlist only demonstrably
read-only gh invocations pass. Anything unrecognised is denied, so a gh
subcommand this script has never heard of cannot slip through as "not a write".
"""

import json
import os
import re
import shlex
import subprocess
import sys

ALLOWED_OWNERS = {"askverea", "marcodeltongo"}

# Demonstrably read-only. Everything else on a foreign repo is denied.
READ_VERBS = {
    "view", "list", "status", "checks", "diff", "search", "browse",
    "clone", "help", "version", "completion", "auth", "config", "alias",
}

GH_BIN = re.compile(r"(?:^|/)gh$")
LAUNCHERS = {"command", "env", "time", "nice", "builtin"}
OPERATOR_CHARS = set("&|;()<>")
NWO = re.compile(r"^([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)(#\d+)?$")
URL_NWO = re.compile(
    r"github\.com[:/]+([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+?)(?:\.git)?(?:[/#?]|$)"
)
API_NWO = re.compile(r"^/?repos/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)")
GQL_OWNER = re.compile(r"owner\s*:\s*[\\\"']*([A-Za-z0-9._-]+)")

FIELD_FLAGS = {"-f", "-F", "--field", "--raw-field", "--input"}
FIELD_PREFIXES = ("--field=", "--raw-field=", "--input=")
METHOD_FLAGS = {"-X", "--method"}

DENY_TEMPLATE = (
    "Blocked: this writes to GitHub under Marco's account on a repo he does not "
    "own ({}). He does not want issues, discussions, PRs, comments or reviews "
    "opened on upstream or third-party repos on his behalf, and he will not "
    "follow those threads, so never promise follow-up there either: no \"happy "
    "to send this as a PR\", no offers to iterate or to answer questions.\n"
    "Do this instead: put the full text of the report in chat as a draft, say "
    "plainly that publishing it is his call, and stop. Do not retry this "
    "command and do not route around the block with another tool."
)


def segments(command):
    """Split a shell command into argv lists, one per simple command.

    Quoting is honoured, so a `|` inside a --jq expression stays part of its
    token instead of cutting the command in half. Raises ValueError when the
    quoting is unbalanced, which the caller treats as unprovable.
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


def local_owner(cwd):
    """Owner of the origin remote in cwd, or None."""
    try:
        url = subprocess.run(
            ["git", "-C", cwd, "remote", "get-url", "origin"],
            capture_output=True, text=True, timeout=5,
        ).stdout.strip()
    except Exception:
        return None
    match = URL_NWO.search(url)
    return match.group(1).lower() if match else None


def positional_owner(tokens):
    """owner/name written as a positional argument.

    Only two shapes are trusted, so that a branch name like `feature/foo` in
    `gh pr checkout feature/foo` is not read as an owner: an explicit issue or
    PR reference (owner/repo#123), and any positional under `gh repo ...`.
    """
    owners = set()
    args = [t for t in tokens[1:] if not t.startswith("-")]
    for arg in args:
        match = NWO.match(arg)
        if not match:
            continue
        if match.group(3) or (args and args[0] == "repo"):
            owners.add(match.group(1).lower())
    return owners


def target_owners(tokens, segment, cwd):
    """Owners this gh invocation addresses."""
    owners = set()
    for i, tok in enumerate(tokens):
        if tok in ("-R", "--repo") and i + 1 < len(tokens):
            match = NWO.match(tokens[i + 1])
            if match:
                owners.add(match.group(1).lower())
        elif tok.startswith("--repo="):
            match = NWO.match(tok.split("=", 1)[1])
            if match:
                owners.add(match.group(1).lower())
        for match in URL_NWO.finditer(tok):
            owners.add(match.group(1).lower())
        match = API_NWO.match(tok)
        if match:
            owners.add(match.group(1).lower())
    owners |= positional_owner(tokens)

    # A GraphQL mutation names its target inside the query, or not at all when
    # it uses an opaque node id. An unprovable target counts as foreign.
    if "graphql" in tokens and re.search(r"\bmutation\b", segment, re.IGNORECASE):
        in_query = {m.group(1).lower() for m in GQL_OWNER.finditer(segment)}
        owners |= in_query or {"<unnamed repository id>"}

    if not owners:
        owner = local_owner(cwd)
        if owner:
            owners.add(owner)
    return owners


def api_is_read_only(tokens, segment):
    """gh api: a plain GET, with no body fields and no GraphQL mutation."""
    for i, tok in enumerate(tokens):
        if tok in METHOD_FLAGS:
            if i + 1 >= len(tokens) or tokens[i + 1].upper() != "GET":
                return False
        elif tok.startswith("--method="):
            if tok.split("=", 1)[1].upper() != "GET":
                return False
        elif tok in FIELD_FLAGS or tok.startswith(FIELD_PREFIXES):
            return False
    if "graphql" in tokens and re.search(r"\bmutation\b", segment, re.IGNORECASE):
        return False
    return True


def is_read_only(tokens, segment):
    """tokens[0] == 'gh'. True only for demonstrably read-only invocations."""
    args = [t for t in tokens[1:] if not t.startswith("-")]
    if not args:
        return True
    if args[0] == "api":
        return api_is_read_only(tokens, segment)
    return any(arg in READ_VERBS for arg in args[:2])


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not re.search(r"(?:^|[\s;|&(])gh\s", command):
        sys.exit(0)
    cwd = payload.get("cwd") or os.getcwd()

    try:
        parsed = segments(command)
    except ValueError:
        emit_deny(
            "This gh command could not be parsed (unbalanced quoting), so the "
            "foreign-repo guard cannot clear it. Rewrite it as a single simple "
            "command, or ask Marco to run it himself."
        )
        return

    for tokens in parsed:
        while tokens and tokens[0] in LAUNCHERS:
            tokens = tokens[1:]
        if not tokens or not GH_BIN.search(tokens[0]):
            continue
        tokens = ["gh"] + tokens[1:]
        segment = " ".join(tokens)

        foreign = sorted(
            o for o in target_owners(tokens, segment, cwd)
            if o not in ALLOWED_OWNERS
        )
        if not foreign:
            continue
        if is_read_only(tokens, segment):
            continue
        emit_deny(DENY_TEMPLATE.format(", ".join(foreign)))
    sys.exit(0)


if __name__ == "__main__":
    main()
