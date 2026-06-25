#!/usr/bin/env bash

# Hermes Skills Web Installer (raw.sh)
# Usage: curl -sL https://raw.githubusercontent.com/Matheusvxz/hermes-skills/main/scripts/raw.sh | bash -- -folder ~/.claude/skills

FOLDER=""
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -folder|--folder)
            FOLDER="$2"
            shift 2
            ;;
        -force|--force)
            FORCE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$FOLDER" ]; then
    echo "Error: Target folder not specified. Use -folder <path>" >&2
    echo "Usage example: curl -sL https://raw.githubusercontent.com/Matheusvxz/hermes-skills/main/scripts/raw.sh | bash -- -folder ~/.agents/skills" >&2
    exit 1
fi

echo "=========================================================="
echo "          HERMES SKILLS WEB INSTALLER                     "
echo "=========================================================="
echo "Target Folder: $FOLDER"
echo "Force Mode:    $FORCE"
echo "----------------------------------------------------------"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
if [ ! -d "$TEMP_DIR" ]; then
    echo "Error: Failed to create temporary directory." >&2
    exit 1
fi

echo "Cloning the hermes-skills repository (main branch)..."
git clone --depth 1 -b main https://github.com/Matheusvxz/hermes-skills.git "$TEMP_DIR"

if [ $? -ne 0 ]; then
    echo "Error: Failed to clone repository." >&2
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Run the installer script
INSTALL_ARGS=("-folder" "$FOLDER")
if [ "$FORCE" = "true" ]; then
    INSTALL_ARGS+=("--force")
fi

echo "Running installation script..."
"$TEMP_DIR/scripts/install_skills.sh" "${INSTALL_ARGS[@]}"
INSTALL_STATUS=$?

# Clean up
rm -rf "$TEMP_DIR"

exit $INSTALL_STATUS
