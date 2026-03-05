#!/usr/bin/env bash
# Claude Code status line - gruvbox style
# Receives JSON session data via stdin

input=$(cat)

# Extract cwd for mise caching
cwd=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('cwd') or d.get('workspace', {}).get('current_dir', ''))
" 2>/dev/null)

# mise active versions — cached 5s
mise_cache="/tmp/claude_sl_mise_${cwd//\//_}"
now=$(date +%s)
mtime=$(stat -f %m "$mise_cache" 2>/dev/null || echo 0)
if [ $((now - mtime)) -gt 5 ] || [ ! -f "$mise_cache" ]; then
  (cd "$cwd" && mise current 2>/dev/null) > "$mise_cache"
fi

# Build status line in Python (unicode icons, gruvbox colors)
STATUSLINE_JSON="$input" STATUSLINE_MISE="$mise_cache" python3 << 'PYEOF'
import os, json, subprocess

d         = json.loads(os.environ.get('STATUSLINE_JSON', '{}'))
mise_file = os.environ.get('STATUSLINE_MISE', '')
venv      = os.environ.get('VIRTUAL_ENV', '')

ctx       = d.get('context_window', {})
cost_data = d.get('cost', {})
model     = d.get('model', {}).get('display_name', '')
worktree  = d.get('worktree')
cwd       = d.get('cwd') or d.get('workspace', {}).get('current_dir', '')

used      = ctx.get('used_percentage')
cost      = cost_data.get('total_cost_usd', 0)
added     = int(cost_data.get('total_lines_added', 0))
removed   = int(cost_data.get('total_lines_removed', 0))

# Git branch
if worktree:
    branch = worktree.get('branch', '')
else:
    r = subprocess.run(['git', '-C', cwd, 'branch', '--show-current'],
                       capture_output=True, text=True)
    branch = r.stdout.strip()

# Language icons (same code points as starship config)
LANG_ICONS = {
    'python': '\ue606',
    'node':   '\ue718',
    'bun':    '\ue76f',
    'rust':   '\ue7a8',
    'go':     '\ue627',
    'zig':    '\U000f240b',
    'elixir': '\ue62d',
    'erlang': '\ue7b1',
}

langs = []
if mise_file and os.path.exists(mise_file):
    with open(mise_file) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 2:
                tool, ver = parts[0].lower(), parts[1]
                if tool in LANG_ICONS:
                    short = '.'.join(ver.split('.')[:2])  # major.minor only
                    langs.append(f'{LANG_ICONS[tool]} {short}')

# Gruvbox 256-color ANSI
R    = '\033[0m'
DIM  = '\033[90m'
YELL = '\033[38;5;214m'  # yellow  — folder
AQUA = '\033[38;5;108m'  # aqua    — branch
BLUE = '\033[38;5;109m'  # blue    — langs
GRN  = '\033[38;5;142m'  # green
YLW  = '\033[38;5;214m'  # yellow (warn)
RED  = '\033[38;5;167m'  # red

ctx_color = DIM if used is None else (RED if used >= 90 else (YLW if used >= 70 else GRN))
used_str  = f'{int(used)}' if used is not None else '?'
folder    = os.path.basename(cwd) if cwd else ''

# Left: project context
left = f'{YELL}{folder}{R}'
if branch:
    left += f'  {AQUA}\u2387 {branch}{R}'
if langs:
    left += f'  {BLUE}' + '  '.join(langs) + R
if venv:
    left += f'  {DIM}({os.path.basename(venv)}){R}'

# Right: session stats
right = f'{DIM}{model}{R}  {ctx_color}ctx {used_str}%{R}  {DIM}${cost:.3f}{R}'
if added or removed:
    right += f'  {GRN}+{added}{R} {RED}-{removed}{R}'

print(f'{left}  {DIM}|{R}  {right}')
PYEOF
