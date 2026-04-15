#!/bin/bash
set -e

echo "Installing Skill Manager..."

# Determine app path
APP_PATH="/Applications/SkillManager.app"

# Download latest release from GitHub
# TODO: Update with actual repo URL
LATEST_URL="https://github.com/your-username/skill-manager/releases/latest/download/SkillManager.zip"

TMP_DIR=$(mktemp -d)
ZIP_FILE="$TMP_DIR/SkillManager.zip"

echo "Downloading latest release..."
curl -L -o "$ZIP_FILE" "$LATEST_URL"

echo "Extracting..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

if [ -d "$APP_PATH" ]; then
    echo "Removing old version..."
    rm -rf "$APP_PATH"
fi

echo "Installing to /Applications..."
cp -R "$TMP_DIR/SkillManager.app" "$APP_PATH"

echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "✅ Skill Manager installed successfully to /Applications/SkillManager.app"
