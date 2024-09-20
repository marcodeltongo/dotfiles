# Function to change to a directory in the Developer folder with shortcuts
# Usage: dev [directory]
dev() {
    local base_dir="$HOME/Developer"
    local target_dir

    case "$1" in
        aur)
            target_dir="$base_dir/audiencerate"
            ;;
        "")
            target_dir="$base_dir"
            ;;
        *)
            target_dir="$base_dir/$1"
            if [ ! -d "$target_dir" ]; then
                # Search for the directory in subdirectories
                found_dir=$(fd -d 3 -t d $1 $base_dir)
                if [ -n "$found_dir" ]; then
                    target_dir="$found_dir"
                fi
            fi
            ;;
    esac

    if [ -d "$target_dir" ]; then
        cd "$target_dir" || return
    else
        echo "Directory not found: $target_dir"
        return 1
    fi
}
