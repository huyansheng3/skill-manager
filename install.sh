#!/bin/bash
set -e

echo "Installing SkillManager..."

# Download the zip
echo "Downloading SkillManager.zip..."
curl -f -L https://h3.static.yximgs.com/kcdn/cdn-kcdn112115/manual-upload/SkillManager-150cabfcc856.zip -o /tmp/SkillManager.zip

# Check SHA256
EXPECTED_SHA256="150cabfcc856afe379e07fa14069ce4ea0f383faf5c9d88c49092306feb9490e"
ACTUAL_SHA256=$(shasum -a 256 /tmp/SkillManager.zip | awk '{print $1}')

if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
    echo "ERROR: SHA256 checksum mismatch"
    echo "Expected: $EXPECTED_SHA256"
    echo "Got:      $ACTUAL_SHA256"
    rm -f /tmp/SkillManager.zip
    exit 1
fi

# Unzip
echo "Unzipping..."
unzip -q /tmp/SkillManager.zip -d /tmp

# Install to /Applications
if [ -d "/Applications/SkillManager.app" ]; then
    echo "Removing old version..."
    rm -rf "/Applications/SkillManager.app"
fi

echo "Installing to /Applications..."
mv /tmp/SkillManager.app /Applications/

# Cleanup
rm -f /tmp/SkillManager.zip

echo ""
echo "🔑 Removing quarantine attribute (required for non-notarized apps)..."
xattr -r -d com.apple.quarantine /Applications/SkillManager.app || true

echo ""
echo "✅ SkillManager installed successfully!"
echo "You can find SkillManager in Launchpad or run: open /Applications/SkillManager.app"
