# Git Cheatsheet (Based on .gitconfig)

## Quick Status & Inspection

```bash
git st                  # Brief status summary
git ds                  # Show staged changes
git hist                # Pretty formatted history
git lo                  # Graph log (all branches)
git last                # Show last commit
git review              # Review changes since last push
git aliases             # List all git aliases
```

## Commits & Undo

```bash
git cm "message"        # Quick commit
git amend               # Amend last commit (no message change)
git reword              # Amend with new message
git uncommit            # Undo last commit (keep changes)
git undo                # Same as uncommit
git undo-hard           # ⚠️ Discard all uncommitted changes
```

## File Operations

```bash
git all                 # Stage all files
git upd                 # Stage updated files only
git unstage <file>      # Unstage file
git untrack <file>      # Remove from tracking (keep local)
```

## Feature Branch Workflow

```bash
git feature <name>      # Create feature branch from main
git bugfix <name>       # Create bugfix branch from main
git pull-main           # Update main branch
git rebase-on-main      # Sync current branch with main
git wip                 # Quick work-in-progress commit
git undo-wip            # Undo WIP commit
git done "msg"          # Stage, commit, and push
git merge-branch        # Squash merge into main
git cleanup-branches    # Delete merged branches
```

## GitHub Integration (requires `gh` CLI)

### Repository

```bash
git browse              # Open repo in browser
git init-private-repo   # Create private GitHub repo
git init-public-repo    # Create public GitHub repo
```

### Pull Requests

```bash
git prs                 # List open PRs
git pr                  # Create PR (opens browser)
git pr-draft            # Create draft PR
git pr-checkout         # Checkout PR locally
git pr-view             # View PR in browser
git pr-status           # Check PR status
git pr-merge            # Merge PR with squash
```

### Issues

```bash
git issues              # List open issues
git my-issues           # List your assigned issues
git issue               # Create new issue
git issue-view <num>    # View issue in browser
```

### CI/CD

```bash
git workflows           # List workflows
git runs                # View recent workflow runs
git run-ci              # Trigger workflow
```

## Forks

```bash
git fork                # Fork repo via GitHub CLI
git set-fork-upstream   # Add upstream remote
git sync-fork           # Sync fork with upstream
```

## Typical Development Session

### 1. Start a New Feature/Bugfix

```bash
git feature user-profile-page
# OR for a bugfix:
git bugfix authentication-error
```

This automatically:
- Checks out `main`
- Pulls latest changes with rebase
- Creates and checks out your new branch

### 2. Develop and Commit Frequently

```bash
# Make code changes...
git upd                                    # Stage updated files
git cm "feat: add user profile component"  # Commit with message

# Check your work
git st                                     # Brief status
git hist                                   # View commit history

# Need to amend?
git all                                    # Stage all changes
git amend                                  # Amend last commit (no edit)
```

### 3. Synchronize with Main (Optional but Recommended)

If your branch is long-lived or `main` has changed:

```bash
git rebase-on-main
```

This automatically:
- Checks out `main` and pulls latest changes
- Returns to your feature branch
- Rebases your work on updated `main`

### 4. Push and Create PR

```bash
git push                    # Push your branch
git pr                      # Create PR (opens browser)
# OR
git pr-draft                # Create draft PR for early feedback
```

### 5. After PR is Merged

Clean up local and remote branches:

```bash
git cleanup-branches
```

This automatically:
- Checks out `main`
- Pulls latest changes and prunes stale remote branches
- Deletes all local merged branches
- Prunes remote branches

### Quick WIP Pattern

For rapid iteration during development:

```bash
git wip                     # Quick WIP commit (skips hooks)
# ... continue working ...
git undo-wip                # Undo WIP, keep changes staged
git cm "proper message"     # Commit with proper message
```

### Emergency Hotfix Pattern

```bash
git bugfix critical-auth-fix
# Make minimal fix
git upd
git cm "hotfix: fix authentication bypass"
git push
git pr                      # Expedited PR process
```

## Configuration Highlights

- **Default branch**: `main`
- **Pull strategy**: rebase (keeps history linear)
- **Push**: auto-setup remote tracking
- **Commits**: GPG signed
- **Merge conflict style**: zdiff3
- **Diff viewer**: delta (side-by-side)
- **Editor**: hx (Helix)
- **Auto-correct**: typos corrected after 3 seconds
