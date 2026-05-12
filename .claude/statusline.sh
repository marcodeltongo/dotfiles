#!/usr/bin/env bash
STATUSLINE_JSON=$(cat) python3 << 'PYEOF'
import os, json, re, subprocess, shutil, concurrent.futures
from datetime import datetime, timezone

d         = json.loads(os.environ.get('STATUSLINE_JSON', '{}'))
venv      = os.environ.get('VIRTUAL_ENV', '')

ctx       = d.get('context_window', {})
cost_data = d.get('cost', {})
model     = d.get('model', {}).get('display_name', '')
effort    = d.get('effort', {}).get('level', '')
fast_mode = d.get('fast_mode', False)
EFFORT    = {'low': 'low', 'medium': 'med', 'high': 'high', 'xhigh': 'max'}

worktree  = d.get('worktree')
cwd       = d.get('cwd') or d.get('workspace', {}).get('current_dir', '')
rl        = d.get('rate_limits', {})

used    = ctx.get('used_percentage')
cost    = cost_data.get('total_cost_usd', 0)
added   = int(cost_data.get('total_lines_added', 0))
removed = int(cost_data.get('total_lines_removed', 0))

rl5 = rl.get('five_hour', {})
rl7 = rl.get('seven_day', {})

def git(*args):
    r = subprocess.run(['git', '-C', cwd] + list(args), capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ''

with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
    f_b = None if worktree else ex.submit(git, 'branch', '--show-current')
    f_d = ex.submit(git, 'status', '--short')
    f_a = ex.submit(git, 'rev-list', '--count', '@{u}..HEAD')
    f_s = ex.submit(git, 'stash', 'list')

branch  = worktree.get('branch', '') if worktree else f_b.result()
dirty   = len(f_d.result().splitlines())
ahead_s = f_a.result()
ahead   = int(ahead_s) if ahead_s.isdigit() else 0
stash   = len(f_s.result().splitlines())

R    = '\033[0m'
DIM  = '\033[90m'
YELL = '\033[38;5;214m'
AQUA = '\033[38;5;108m'
GRN  = '\033[38;5;142m'
RED  = '\033[38;5;167m'

MODEL_COLORS = {'haiku': '\033[38;5;109m', 'opus': '\033[38;5;208m'}
MODEL_C = next((c for k, c in MODEL_COLORS.items() if k in model.lower()), '\033[38;5;175m')

def pct_rgb(pct):
    if pct is None:
        return DIM
    p = max(0, min(100, pct)) / 100
    if p <= 0.5:
        t = p * 2
        r, g, b = int(80 + t * 140), 200, int(80 * (1 - t))
    else:
        t = (p - 0.5) * 2
        r, g, b = 220, int(200 - t * 150), int(t * 50)
    return f'\033[38;2;{r};{g};{b}m'

def make_bar(pct, width=10):
    filled = round((pct or 0) / 100 * width)
    color  = pct_rgb(pct)
    return f'{color}{"█" * filled}{DIM}{"░" * (width - filled)}{R}'

INTERVALS = [(86400, 'd'), (3600, 'h'), (60, 'm')]

def fmt_reset(ts):
    if not ts:
        return ''
    try:
        dt = datetime.fromtimestamp(ts, tz=timezone.utc) if isinstance(ts, (int, float)) else datetime.fromisoformat(str(ts))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        sec = (dt - datetime.now(tz=timezone.utc)).total_seconds()
        if sec <= 0:
            return ''
        for div, unit in INTERVALS:
            if sec >= div:
                return f' in {int(sec // div)}{unit}'
        return ''
    except Exception:
        return ''

def rl_part(data, label):
    pct = data.get('used_percentage')
    if pct is None:
        return ''
    reset = fmt_reset(data.get('resets_at'))
    return f'{DIM}{label}{R} {pct_rgb(pct)}{int(pct)}%{reset}{R}'

ANSI_RE = re.compile(r'\033\[[0-9;]*m')
def vlen(s):
    return len(ANSI_RE.sub('', s))

folder = os.path.basename(cwd) if cwd else ''

left = f'{YELL}{folder}{R}'
if branch:
    left += f'  {AQUA}⎇ {branch}{R}'
if dirty:
    left += f'  {YELL}~{dirty}{R}'
if ahead:
    left += f'  {AQUA}↑{ahead}{R}'
if stash:
    left += f'  {DIM}≡{stash}{R}'
if added or removed:
    left += f'  {GRN}+{added}{R} {RED}-{removed}{R}'
if venv:
    left += f'  {DIM}({os.path.basename(venv)}){R}'

model_part = f'{MODEL_C}{model}{R}'
if effort in EFFORT:
    model_part += f' {DIM}{EFFORT[effort]}{R}'
if fast_mode:
    model_part += f' {DIM}fast{R}'

ctx_color = pct_rgb(used)
ctx_part  = f'{make_bar(used)} {ctx_color}{int(used) if used is not None else "?"}%{R}'

rl_parts = [p for p in [rl_part(rl5, '5h'), rl_part(rl7, '7d')] if p]

right = f'{model_part}  {ctx_part}'
if rl_parts:
    right += '  ' + '  '.join(rl_parts)
right += f'  {DIM}${cost:.1f}{R}'

try:
    cols = os.get_terminal_size(2).columns
except OSError:
    try:
        with open('/dev/tty') as tty:
            cols = os.get_terminal_size(tty.fileno()).columns
    except OSError:
        cols = shutil.get_terminal_size(fallback=(120, 0)).columns

pad = max(2, cols - vlen(left) - vlen(right) - 4)
print(left + ' ' * pad + right)
PYEOF
