# Function to make a directory with intermediates and cd into it
# Usage: mkcd [directory]
function mkcd() {
  if [[ -z "$1" ]]; then
    echo "Error: Please enter a directory name" >&2
    return 1
  elif [[ -d "$1" ]]; then
    echo "Warning: Directory '$1' already exists" >&2
    cd "$1" || return 1
  else
    mkdir -p "$1" && cd "$1" || return 1
  fi
}
