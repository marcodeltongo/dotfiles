# Environment

**Shell:** Fish (user terminal) — bash for tool calls
**Editors:** `hx` (terminal), `zed --wait` (visual)
**OS:** macOS Apple Silicon — Homebrew at `/opt/homebrew/bin`
**Projects:** `~/Developer/` (organized via git-get)

## Package Management

Detect from lockfile, never assume:

| Lockfile | Manager |
|----------|---------|
| `pnpm-lock.yaml` | `pnpm` |
| `bun.lock` / `bun.lockb` | `bun` |
| `package-lock.json` | `npm` |
| `yarn.lock` | `yarn` |
| `uv.lock` | `uv` |
| `poetry.lock` | `poetry` |
| `Pipfile.lock` | `pipenv` |

No lockfile + `package.json` → default to `npm`. Version manager: `mise`.

### Tool-specific commands

| Instead of | Use |
|-----------|-----|
| `pip install` | `uv add` |
| `pip install -r requirements.txt` | `uv sync` |
| `python script.py` | `uv run script.py` |
| `npx <tool>` | `pnpm dlx` / `bunx` / `bun x` |
| `npm run <script>` | check `mise.toml [tasks]` first, then `mise run <task>` |

## Git

**Identity:** Marco Del Tongo <info@marcodeltongo.com>
**Config:** GPG signing enabled — never use `--no-verify`, default branch = `main`, pull = rebase

- Never use `--no-verify` (GPG signing always active)
- Feature branches: `feature/<name>` or `bugfix/<name>` off `main`
- Finish features with squash-merge into `main`, then delete branch
- Prefer worktrees for parallel/isolated work: `claude -w <name>` or ask me to start one
