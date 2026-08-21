function verea-done
    # Finalize a verea-* worktree (a standalone clone created by
    # verea-issue / verea-pr). Run from inside the worktree directory:
    #
    #   verea-done                 interactive (confirmation)
    #   verea-done --force         skip the confirmation before rm -rf
    #
    # Steps:
    #   1. tear down the worktree's dev stack if it's up (avoids Docker
    #      orphans — db:down = `docker compose down`, keeps the data volume)
    #   2. cd into the parent and rm -rf the old cwd
    #   3. always run docker-prune-worktree-orphans.sh to reap any orphaned
    #      worktree Docker stacks (containers/volumes/networks/images)
    #
    # NOTE: origin/<branch> is never touched from the CLI (project rule) —
    # remote branches are managed through the GitHub UI / PR flow only.
    argparse 'f/force' -- $argv
    or return 2

    set -l cwd (pwd)
    set -l parent (dirname -- "$cwd")
    set -l name (basename -- "$cwd")

    # --- guards -------------------------------------------------------
    if test "$parent" = "$cwd"
        echo "verea-done: refusing to remove root" >/dev/stderr
        return 1
    end
    if not string match -q 'verea-*' -- "$name"
        echo "verea-done: \"$name\" is not a verea-* worktree" >/dev/stderr
        return 1
    end
    if not git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "verea-done: \"$name\" is not a git checkout" >/dev/stderr
        return 1
    end

    echo "Finishing worktree: $name"

    # --- warn about uncommitted changes -------------------------------
    set dirty (git -C "$cwd" status --porcelain 2>/dev/null | string collect)
    if test -n "$dirty"
        echo "Warning: uncommitted changes in $name will be deleted:"
        git -C "$cwd" status --short | sed -n '1,20p'
    end

    # --- 1. tear down dev stack if up ---------------------------------
    set -l compose_file "$cwd/infra/docker/docker-compose.yml"
    set stack_up (docker ps -a --filter "label=com.docker.compose.project.config_files=$compose_file" --format '{{.ID}}' 2>/dev/null)
    if test -n "$stack_up"
        echo "→ dev stack is up, bringing it down via 'mise run db:down'"
        set -l from (pwd)
        cd "$cwd"
        mise run db:down; or echo "verea-done: warning: 'mise run db:down' failed" >/dev/stderr
        cd "$from"
    else
        echo "→ no dev stack running"
    end

    # --- confirmation before rm -rf -----------------------------------
    if not set -q _flag_force
        read -P "Remove $name? Uncommitted changes will be lost. [y/N] " resp
        if test (string lower -- "$resp") != y
            echo "Aborted."
            return 1
        end
    end

    cd "$parent"
    rm -rf "$cwd"
    echo "Removed $cwd"

    # --- 3. always reap orphaned worktree Docker stacks -----------------
    # Stacks whose worktree dir is gone (from any clone/flow) leave
    # containers, volumes and ~650MB postgres images behind — clean them
    # every time.
    set -l prune_script "$HOME/Developer/askverea/verea/scripts/docker-prune-worktree-orphans.sh"
    if not test -f "$prune_script"
        set prune_script "$HOME/Developer/askverea/verea-codex/scripts/docker-prune-worktree-orphans.sh"
    end
    if test -f "$prune_script"
        echo "→ pruning orphaned worktree Docker resources"
        # Run with `sh` (repo scripts aren't +x; mise already calls them the
        # same way, e.g. `sh scripts/ports-summary.sh`).
        command sh "$prune_script"
    else
        echo "verea-done: prune script not found, skipping" >/dev/stderr
    end
end
