#!/bin/bash
# build.sh — Build and install ClockLock screen saver
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$SCRIPT_DIR/ClockLock.xcodeproj"
SAVER_DEST="$HOME/Library/Screen Savers/ClockLock.saver"

echo "🕐 Building ClockLock screen saver..."

# Build Release configuration
xcodebuild \
  -project "$PROJECT" \
  -target "ClockLock" \
  -configuration Release \
  -arch arm64 \
  build \
  CONFIGURATION_BUILD_DIR="$SCRIPT_DIR/build"

echo "📦 Installing to ~/Library/Screen Savers/..."
# Remove old version if present
if [ -d "$SAVER_DEST" ]; then
  rm -rf "$SAVER_DEST"
fi
cp -R "$SCRIPT_DIR/build/ClockLock.saver" "$SAVER_DEST"

echo "✅ Done! ClockLock.saver installed."
echo ""
echo "➡️  Open System Settings → Screen Saver to activate it."
echo "   Click 'Options' to choose your clock face and background."
