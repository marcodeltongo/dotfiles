# Environment

**Shell:** Fish — use `fish -c "..."` in tool calls to access Fish functions (e.g. `dotfiles`)
**Editors:** `hx` (terminal), `gram --wait` (visual)
**OS:** macOS Apple Silicon — Homebrew at `/opt/homebrew/bin`
**Projects:** `~/Developer/` (organized via git-get)

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

**Runtime manager: `mise`** — manages Python, Node, Go, Rust, Bun, pnpm globally. Never suggest `nvm`, `pyenv`, `rbenv`, or similar; always use `mise use` / `mise install`.

### Tool-specific commands

| Instead of | Use |
|-----------|-----|
| `pip install` | `uv add` |
| `pip install -r requirements.txt` | `uv sync` |
| `python script.py` | `uv run script.py` |
| `npx <tool>` | `pnpm dlx` / `bunx` / `bun x` |
| `npm run <script>` | check `mise.toml [tasks]` first, then `mise run <task>` |

## CLI Tools

Prefer modern alternatives when running shell commands:

| Instead of | Use | Notes |
|-----------|-----|-------|
| `grep` | `rg` | ripgrep — faster, respects .gitignore |
| `find` | `fd` | simpler syntax, respects .gitignore |
| `ls` | `eza` | colors, git status, tree support |
| `curl` / `wget` | `xh` | httpie-compatible, cleaner output |
| `cat` (terminal) | `bat` | syntax highlighting, line numbers |
| `python -c json` / manual JSON | `jq` | JSON processing |
| `open`/browser for markdown | `glow` | render markdown in terminal |

GitHub operations: use `gh` CLI. Docker TUI: `lazydocker`. Git TUI: `lazygit`.

## Dotfiles

Config files are tracked via a bare git repo at `~/.dotfiles/`. Use the `dotfiles` Fish function (alias for `git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`) to stage and commit changes:

```bash
dotfiles add .config/mise/config.toml
dotfiles commit -m "Update mise config"
dotfiles push
```

## Git

**Identity:** Marco Del Tongo <info@marcodeltongo.com>
**Config:** GPG signing enabled — never use `--no-verify`, default branch = `main`, pull = rebase

- Never use `--no-verify` (GPG signing always active)
- Feature branches: `feature/<name>` or `bugfix/<name>` off `main`
- Finish features with squash-merge into `main`, then delete branch
- Prefer worktrees for parallel/isolated work: `claude -w <name>` or ask me to start one

## Behavior

**Language:** Respond in Italian. All code, variable names, comments, commit messages, and documentation must remain in English.

- Delete unused or removed code outright — never comment it out
- Keep responses terse and direct; no trailing summaries of what was just done

### Before coding

- State assumptions explicitly. If uncertain, ask — don't silently pick an interpretation.
- If multiple valid approaches exist, present them with tradeoffs; don't choose without saying so.
- If a simpler path exists, say so and push back if warranted.

### Surgical changes

- Touch only what the task requires. Don't "improve" adjacent code, formatting, or comments.
- Match existing style even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove only imports/variables/functions that *your* changes made unused.

### Goal-driven execution

For multi-step tasks, state a brief plan upfront:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```
Transform vague tasks into verifiable goals before starting ("fix the bug" → "write a test that reproduces it, then make it pass").