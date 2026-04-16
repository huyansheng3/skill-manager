#!/bin/bash
set -e

# SkillManager Release Script
# Automates build → app bundle → zip → sha256 → hash filename → upload → update install script/Formula

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$PROJECT_ROOT/SkillManager.app"
ZIP_BASE_NAME="SkillManager.zip"
ZIP_PATH="$PROJECT_ROOT/$ZIP_BASE_NAME"
BUILD_BIN="$PROJECT_ROOT/SkillManager/.build/release/SkillManager"
CDN_BASE_URL="https://h3.static.yximgs.com/kcdn/cdn-kcdn112115/manual-upload"

echo "🚀 SkillManager Release Process"
echo "================================="

# Step 1: Clean previous build
echo ""
echo "🧹 Cleaning previous build..."
rm -rf "$APP_PATH"
rm -f "$PROJECT_ROOT"/SkillManager*.zip

# Step 2: Build using swift package
echo ""
echo "🔨 Building with swift package..."
cd "$PROJECT_ROOT/SkillManager"
swift build -c release

# Step 3: Assemble .app bundle
echo ""
echo "📦 Assembling macOS app bundle..."
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp "$BUILD_BIN" "$APP_PATH/Contents/MacOS/SkillManager"
chmod +x "$APP_PATH/Contents/MacOS/SkillManager"
cp "$PROJECT_ROOT/SkillManager/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$PROJECT_ROOT/SkillManager/Resources/SkillManager.icns" "$APP_PATH/Contents/Resources/SkillManager.icns"

# Step 4: Create zip archive
echo ""
echo "🗜️  Creating zip archive..."
cd "$PROJECT_ROOT"
zip -q -r "$ZIP_PATH" SkillManager.app

# Step 5: Calculate SHA256 and rename file with hash
echo ""
echo "🔐 Calculating SHA256 checksum..."
SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
SHORT_HASH="${SHA256:0:12}"
HASHED_ZIP_NAME="SkillManager-${SHORT_HASH}.zip"
HASHED_ZIP_PATH="$PROJECT_ROOT/$HASHED_ZIP_NAME"
mv "$ZIP_PATH" "$HASHED_ZIP_PATH"
ZIP_PATH="$HASHED_ZIP_PATH"
ZIP_URL="$CDN_BASE_URL/$HASHED_ZIP_NAME"
ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)
echo "   File: $HASHED_ZIP_NAME"
echo "   Size: $ZIP_SIZE"
echo "   SHA256: $SHA256"

# Step 6: Update install.sh
echo ""
echo "📝 Updating install.sh with new URL and SHA256..."
sed -i '' "s|curl -f -L https://h3.static.yximgs.com/kcdn/cdn-kcdn112115/manual-upload/[^ ]* -o /tmp/SkillManager.zip|curl -f -L $ZIP_URL -o /tmp/SkillManager.zip|" "$PROJECT_ROOT/install.sh"
sed -i '' "s/EXPECTED_SHA256=\"[^\"]*\"/EXPECTED_SHA256=\"$SHA256\"/" "$PROJECT_ROOT/install.sh"

# Step 7: Update Homebrew Formula
echo ""
echo "🍺 Updating Homebrew Formula..."
sed -i '' "s|url \"https://h3.static.yximgs.com/kcdn/cdn-kcdn112115/manual-upload/[^\"]*\"|url \"$ZIP_URL\"|" "$PROJECT_ROOT/Formula/skill-manager.rb"
sed -i '' "s/sha256 \"[^\"]*\"/sha256 \"$SHA256\"/" "$PROJECT_ROOT/Formula/skill-manager.rb"

# Step 8: Upload to KCDN
echo ""
echo "☁️  Uploading to KCDN..."
cd "$PROJECT_ROOT"
if which python3 >/dev/null 2>&1; then
    python3 ~/.claude/skills/kcdn-uploader/scripts/upload_file.py "$ZIP_PATH" --project kwaipilot-external
else
    python ~/.claude/skills/kcdn-uploader/scripts/upload_file.py "$ZIP_PATH" --project kwaipilot-external
fi

echo ""
echo "✅ Release completed!"
echo ""
echo "Next steps:"
echo "  1. Commit Formula/skill-manager.rb and install.sh changes"
echo "  2. Tag the release: git tag v1.0.x"
echo "  3. Push to remote"
