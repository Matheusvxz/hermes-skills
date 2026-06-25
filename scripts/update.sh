#!/usr/bin/env bash

# Get repository root directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Navigating to repository folder: $REPO_DIR"
cd "$REPO_DIR" || exit 1

echo "Checking for updates..."
if git pull; then
    echo "Success: Repository updated successfully!"
else
    echo "Error: git pull failed. Please verify your connection or resolve local conflicts."
    exit 1
fi
