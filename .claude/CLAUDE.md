# Environment

The facts in this section were verified on 2026-08-28 and they decay on their own: re-check one
before you lean on it. The directives in the rest of the file do not expire the same way.

**Editors:** `hx` (terminal), `gram --wait` (visual)
**OS:** macOS Apple Silicon, Homebrew at `/opt/homebrew/bin`
**Hardware:** Apple M4, 10 cores, 16 GB RAM. Keep parallelism modest: a wide monorepo build
competes with the editor, Docker and the browser for the same 16 GB.
**Projects:** `~/Developer/<org>/<repo>`
**Runtimes:** global `mise` config in `~/.config/mise/config.toml` keeps python, uv, go, node, bun
and rust on `latest`; `~/Developer/` is in `trusted_config_paths`, so per-repo `mise.toml` activates
without a trust prompt.

## Shell

Fish (`/opt/homebrew/bin/fish`) is the login shell, but the two halves of a session do not share it.

- **Your own tool calls** do not necessarily inherit fish: in the desktop app they run in `/bin/zsh`,
  and the harness prompt may claim fish while they do. Write POSIX-compatible commands there, and
  reach Fish functions (e.g. `dotfiles`) through `fish -c "..."`. When it matters, settle it with
  `echo $ZSH_VERSION$BASH_VERSION$FISH_VERSION`.
- Under zsh a glob that matches nothing stops that one command from running: the shell reports
  `no matches found`, the status is non-zero, and the script carries on (measured 2026-09-06,
  inside `if !` and bare). The message comes from the shell before the command starts, so a
  `2>/dev/null` on the command never hides it. Quote patterns meant for the tool rather than for
  the shell (`rg --glob '*.ts'`), and where matching nothing is a legitimate outcome use `find`
  instead of a glob: under bash the same glob stays literal and the command fails on its own,
  so a glob makes the branch read differently in each shell.
- **Commands you hand to Marco** get pasted into his fish terminal, so those go in Fish syntax:
  `set -x VAR value` (not `export VAR=value`), `env VAR=value cmd` (fish has no prefix assignment),
  `$fish_pid` (not `$$`), and no heredocs (use `printf`, or write the file with a tool). `&&`,
  `$(...)` and `&>` are fine on fish 4.x.
- Keep the `` ```bash `` fence tag on those blocks anyway: it is the marker that gives the block a
  Run button, not a claim about the dialect.

## Package Management

Detect from lockfile, never assume:

| Lockfile | Manager |
|----------|---------|
| `aube-lock.yaml` | `aube` |
| `pnpm-lock.yaml` | `pnpm` |
| `bun.lock` / `bun.lockb` | `bun` |
| `package-lock.json` | `npm` |
| `yarn.lock` | `yarn` |
| `uv.lock` | `uv` |
| `poetry.lock` | `poetry` |
| `Pipfile.lock` | `pipenv` |

No lockfile + `package.json` → default to `npm`.

**Runtime manager: `mise`** manages python, uv, node, bun, go and rust globally
(`~/.config/mise/config.toml`), plus whatever each repo's own `mise.toml` pins. Never suggest
`nvm`, `pyenv`, `rbenv`, or similar; always use `mise use` / `mise install`.

### Tool-specific commands

| Instead of | Use |
|-----------|-----|
| `pip install` | `uv add` |
| `pip install -r requirements.txt` | `uv sync` |
| `python script.py` | `uv run script.py` |
| `npx <tool>` | `bunx` (`pnpm dlx` only in a repo whose lockfile says pnpm: it is not installed globally) |
| `npm run <script>` | check `mise.toml [tasks]` first, then `mise run <task>` |

## CLI Tools

Installed and preferred in Marco's terminal: `rg`, `fd`, `eza`, `bat`, `xh`, `jq`, `glow`, `gh`,
`lazygit`, `lazydocker`, `delta`, `hunk`. GitHub work goes through `gh`.

In your own tool calls the half that earns its place is `rg`, `fd`, `jq` and `gh`. Prefer plain
`ls` and `cat` over `eza`, `bat` and `glow`: colour and layout are output you then have to read
around.

## Dotfiles

Config files are tracked via a bare git repo at `~/.dotfiles/`. Use the `dotfiles` Fish function (alias for `git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`) to stage and commit changes:

```bash
dotfiles add .config/mise/config.toml
dotfiles commit -m "Update mise config"
```

`~/.gitignore` starts with `*` and un-ignores single paths with `!`. That line is load-bearing:
it is what stops `dotfiles add -A` from swallowing the entire home directory. Never tidy it up.

`dotfiles push` publishes. Confirm before running it, unlike `add` and `commit`.

## Git

**Identity:** Marco Del Tongo <info@marcodeltongo.com>

- Never use `--no-verify`. It skips the hooks (hk: lint, format, gitleaks) and it never skips the
  signature: `commit.gpgsign` and `tag.gpgsign` are on, so the commit is signed either way. The rule
  protects the gates, not the signing.
- Feature branches: `feature/<name>` or `bugfix/<name>` off `main`
- Finish features with squash-merge into `main`, then delete branch
- Branch-worthy work (anything that will commit, branch, or open a PR) starts in a dedicated worktree:
  call the `EnterWorktree` tool at the start of the task, without asking. Read-only exploration and
  answering questions can stay in the main checkout. `claude -w <name>` starts one from the shell.
  Why: a shared checkout means the working tree, index, stash, and `.git/config` are shared with any
  concurrent session, so a branch can inherit someone else's HEAD and a stash can displace their work.
- Base every worktree on an up-to-date `origin/main`, never on local HEAD: `git fetch origin main` first.
  `EnterWorktree` branches from `origin/<default>` because `worktree.baseRef` defaults to `fresh`, but that
  ref is only as current as the last fetch, and a `head` value would silently undo it. Verify after creating
  one with `git merge-base --is-ancestor HEAD origin/main`.

## Upstream and third-party repos

Never publish to a GitHub repo outside `askverea/*` and `marcodeltongo/*`: no issues,
discussions, PRs, comments, reviews, or forks, however clearly the bug is upstream and
however ready the report is. A `PreToolUse` hook (`~/.claude/hooks/gh-foreign-repo-guard.py`)
blocks the `gh` path; this rule binds every other path too (MCP, browser, curl).

- Deliver an upstream finding as a draft in chat: title, body, repro, and where it would go.
  Publishing it, editing it, or dropping it is Marco's call.
- Never write anything that commits him to follow-up on someone else's thread. No "happy to
  send this as a PR", no offers to iterate, test, or answer questions: he will not be reading
  that thread, so the offer is one he never made.
- Land the finding where our own work can use it instead: a memory, an issue on
  `askverea/verea`, or a comment next to the workaround it explains.

## Behavior

**Language:** `~/.claude/settings.json` already sets `"language": "italian"` for every client, so
the chat side needs no rule here. What it does not cover, and what this line is for: anything written
into the repo or into GitHub stays in English whatever language the conversation is in. Code,
identifiers, comments, commit messages, branch names, issues, PRs, reviews, documentation.

- Delete unused or removed code outright, never comment it out
- Keep responses terse and direct; no trailing summaries of what was just done
- No em dashes in anything you write: chat, GitHub issues and PRs, commit messages, code comments.
  Restructure the sentence rather than swapping in another dash.

### Before coding

- Uncertainty is a research task before it is a question. If the answer is in the repo, the
  lockfile, the git history or the machine, go and get it. Asking Marco something you could have
  verified hands your work back to him.
- If it cannot be verified and the choice does not steer the work, take the sensible default, say
  out loud which one you took, and carry on. Never pick an interpretation silently.
- If it cannot be verified, several approaches are defensible, and the choice sets a direction that
  is expensive to undo, ask before you build. Present the options with their tradeoffs and say which
  one you recommend.
- Ask where the answer is actually needed, and meanwhile finish everything that does not depend on
  it. An open question must not park work that was never blocked.
- If a simpler path exists, say so and push back if warranted.

### Surgical changes

- Touch only what the task requires. Don't "improve" adjacent code, formatting, or comments.
- Match existing style even if you'd do it differently.
- If you notice unrelated dead code, mention it rather than deleting it.
- Remove only imports/variables/functions that *your* changes made unused.

### Goal-driven execution

Turn a vague task into a verifiable goal before starting: "fix the bug" becomes "write a test that
reproduces it, then make it pass". For multi-step work, state the steps upfront and, for each one,
the check that proves it landed.