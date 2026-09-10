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
# A mutation addressed by node id names no owner in its text. These pick the
# ids out so they can be resolved against GitHub rather than guessed at: any
# `<something>Id: "..."` inside the query, and any `-F id=...` style field.
# Over-matching is safe in one direction only, which is the direction that
# matters: a string that is not really a node id fails to resolve and keeps the
# command denied, so a loose pattern can tighten the guard but never loosen it.
NODE_ID = re.compile(
    r"[A-Za-z_]*[Ii]d\s*[:=]\s*\\?[\"']?([A-Za-z0-9_=+/-]{16,})\\?[\"']?"
)
NODE_OWNER_QUERY = """query($id:ID!){node(id:$id){__typename
  ... on Repository{nameWithOwner}
  ... on Issue{repository{nameWithOwner}}
  ... on IssueComment{repository{nameWithOwner}}
  ... on PullRequest{repository{nameWithOwner}}
  ... on PullRequestReview{repository{nameWithOwner}}
  ... on PullRequestReviewComment{repository{nameWithOwner}}
  ... on PullRequestReviewThread{repository{nameWithOwner}}
  ... on Discussion{repository{nameWithOwner}}
  ... on DiscussionComment{discussion{repository{nameWithOwner}}}}}"""

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


def find_nwo(value):
    """First nameWithOwner anywhere in a GraphQL node, or None."""
    if isinstance(value, dict):
        found = value.get("nameWithOwner")
        if isinstance(found, str) and "/" in found:
            return found
        for nested in value.values():
            found = find_nwo(nested)
            if found:
                return found
    return None


def node_owners(segment):
    """Owners behind opaque node ids, asked of GitHub rather than inferred.

    Resolving a review thread, or anything else addressed by node id, cannot
    name its repository in the query text, so treating every such mutation as
    foreign blocks a legitimate workflow with no way to express itself. The id
    is resolvable, and the answer comes from GitHub rather than from the caller,
    so it is evidence and not a hint.

    Returns (owners, unprovable). `unprovable` stays True whenever an id could
    not be turned into a repository, which keeps an offline machine, a stale id,
    a node type not listed above and a missing `gh` on the same side of the line
    as before this function existed: denied.
    """
    ids = {m.group(1) for m in NODE_ID.finditer(segment)}
    if not ids:
        return set(), True
    owners, unprovable = set(), False
    for node_id in sorted(ids):
        try:
            result = subprocess.run(
                ["gh", "api", "graphql",
                 "-f", "query=" + NODE_OWNER_QUERY, "-F", "id=" + node_id],
                capture_output=True, text=True, timeout=10,
            )
            node = (json.loads(result.stdout).get("data") or {}).get("node") or {}
        except Exception:
            unprovable = True
            continue
        # Walk for nameWithOwner rather than reading a fixed path: the field sits
        # at a different depth per node type (a DiscussionComment reaches it
        # through its discussion), and a shape added later should widen what
        # resolves rather than silently join the unprovable pile.
        nwo = find_nwo(node)
        if nwo and "/" in nwo:
            owners.add(nwo.split("/", 1)[0].lower())
        else:
            unprovable = True
    return owners, unprovable


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
        if in_query:
            owners |= in_query
        else:
            resolved, unprovable = node_owners(segment)
            owners |= resolved
            if unprovable or not resolved:
                owners.add("<unnamed repository id>")

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
