#!/usr/bin/env bash

# Get current script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SOURCE_DIR="$ROOT_DIR/skills"

# Function to show usage help
show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -folder, --folder PATH   Target folder where the skills will be installed"
    echo "  -f, --force              Overwrite skills if they already exist in the target directory"
    echo "  -h, --help               Display this help message"
    echo
}

# Parse options
FORCE=false
DEST_INPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force|-f)
            FORCE=true
            shift
            ;;
        --folder|-folder)
            DEST_INPUT="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            # Ignore unknown flags to stay resilient
            shift
            ;;
    esac
done

# Verify if there are skills to install
if [ ! -d "$SKILLS_SOURCE_DIR" ]; then
    echo "Error: 'skills' directory not found in repository at: $SKILLS_SOURCE_DIR"
    exit 1
fi

SKILLS=()
for d in "$SKILLS_SOURCE_DIR"/*; do
    if [ -d "$d" ]; then
        SKILLS+=("$(basename "$d")")
    fi
done

if [ ${#SKILLS[@]} -eq 0 ]; then
    echo "Error: No skills found to install in $SKILLS_SOURCE_DIR."
    exit 1
fi

echo "=========================================================="
echo "          HERMES SKILLS INSTALLATION                      "
echo "=========================================================="
echo "Skills found for installation:"
for skill in "${SKILLS[@]}"; do
    echo "  - $skill"
done
echo "----------------------------------------------------------"

# Ask for destination directory if not provided as argument
if [ -z "$DEST_INPUT" ]; then
    read -p "Enter destination folder for the skills (e.g., ~/.agents/skills): " DEST_INPUT
fi

if [ -z "$DEST_INPUT" ]; then
    echo "Error: Target directory cannot be empty."
    exit 1
fi

# Expand tilde (~) to Home folder if applicable
DEST_DIR="${DEST_INPUT/#\~/$HOME}"

# Check for existing folder conflicts
CONFLICTING_SKILLS=()
for skill in "${SKILLS[@]}"; do
    if [ -d "$DEST_DIR/$skill" ]; then
        CONFLICTING_SKILLS+=("$skill")
    fi
done

# Fail if conflicts exist and --force was not supplied
if [ ${#CONFLICTING_SKILLS[@]} -gt 0 ]; then
    if [ "$FORCE" = "false" ]; then
        echo "----------------------------------------------------------"
        echo "ERROR: Installation aborted. The following skills already exist at target:"
        for skill in "${CONFLICTING_SKILLS[@]}"; do
            echo "  - $DEST_DIR/$skill"
        done
        echo "----------------------------------------------------------"
        echo "Tip: Run the script with --force to overwrite existing directories:"
        echo "  $0 --force"
        exit 1
    else
        echo "Warning: Overwriting the following existing skills (--force enabled):"
        for skill in "${CONFLICTING_SKILLS[@]}"; do
            echo "  - $skill"
        done
    fi
fi

# Create target directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    echo "Creating target directory at $DEST_DIR..."
    mkdir -p "$DEST_DIR"
fi

# Copying skills
echo "Copying skills to $DEST_DIR..."
for skill in "${SKILLS[@]}"; do
    # Remove existing folder if force copying
    if [ -d "$DEST_DIR/$skill" ]; then
        rm -rf "$DEST_DIR/$skill"
    fi
    
    cp -r "$SKILLS_SOURCE_DIR/$skill" "$DEST_DIR/"
    echo "  [ OK ] $skill copied successfully."
done

echo "----------------------------------------------------------"
echo "Installation completed successfully!"
echo "=========================================================="
