function _wt_prepare --argument-names repo_url clone_dir branch create
    # clone-or-reuse, fetch the target branch (shallow), checkout, then mise setup.
    # `create=1` creates a new local branch (issue workflow); otherwise checks
    # out an existing remote branch (PR workflow).
    if test -d "$clone_dir"
        echo "Reusing $clone_dir"
        cd $clone_dir
        git fetch --all --prune
        or return 1
    else
        git clone --depth 1 "$repo_url" $clone_dir
        or return 1
        cd $clone_dir
    end

    # Fetch the target branch. The explicit refspec also lands it in
    # refs/remotes/origin/ (a bare shallow fetch only writes FETCH_HEAD),
    # then check out from FETCH_HEAD: in a fresh shallow clone a plain
    # `git checkout <branch>` (or --track) fails with "pathspec did not
    # match" / "is not a branch" because the ref is shallow.
    if test "$create" != 1; and test -n "$branch"
        git fetch --depth 1 origin "$branch:refs/remotes/origin/$branch"
        or return 1
    end

    if test "$create" = 1
        # -B (not -b): idempotent on re-runs — re-point the local branch at
        # HEAD instead of failing with "a branch named ... already exists".
        # Refuses to clobber uncommitted local changes.
        git checkout -B "$branch"
    else
        # -B: re-point the review worktree at the freshly fetched head.
        git checkout -B "$branch" FETCH_HEAD
    end
    or return 1

    mise run setup
    or return 1
end
