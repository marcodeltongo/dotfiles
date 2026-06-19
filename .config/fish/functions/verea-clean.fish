function verea-clean
    # Remove the current worktree: cd into its parent, then `rm -rf` the old cwd.
    # Expects to be run from inside a `verea-*` worktree directory.
    set -l cwd (pwd)
    set -l parent (dirname $cwd)
    set -l name (basename $cwd)

    if test "$parent" = "$cwd"
        echo "Error: refusing to remove root" >/dev/stderr
        return 1
    end

    if not string match -q 'verea-*' -- "$name"
        echo "Error: cwd \"$name\" is not a verea-* worktree" >/dev/stderr
        return 1
    end

    cd $parent
    rm -rf "$cwd"
    echo "Removed $cwd"
end
