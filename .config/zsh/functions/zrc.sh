# Function to edit existing zsh and dotfiles configuration files
# Usage: zrc
zrc() {
    # Array of configuration files to potentially edit
    local files=(
        ~/.zshrc
        ~/.config/wezterm/wezterm.lua
        ~/.config/starship.toml
        ~/.config/direnv/direnv.toml
        ~/.config/topgrade.toml
        ~/.zshenv
        ~/.zprofile
        ~/.profile
        ~/.gitconfig
    )

    # Initialize array for existing files
    local existing_files=()

    # Check each file and add to existing_files if it exists
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            existing_files+=("$file")
        fi
    done

    # Add custom functions from zsh functions directory
    existing_files+=("$(fd -t f . ~/.config/zsh/functions)")

    # Edit existing files or create ~/.zshrc if none exist
    if [[ ${#existing_files[@]} -gt 0 ]]; then
        $EDIT "${existing_files[@]}"
    else
        echo "No existing files found to edit. Creating ~/.zshrc"
        touch ~/.zshrc
        $EDIT ~/.zshrc
    fi
}
