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

    # Only fetch the branch when it should already exist on the remote.
    if test "$create" != 1; and test -n "$branch"
        git fetch --depth 1 origin "$branch"
        or return 1
    end

    if test "$create" = 1
        git checkout -b "$branch"
    else
        git checkout "$branch"
    end
    or return 1

    mise run setup
    or return 1
end
