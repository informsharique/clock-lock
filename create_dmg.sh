#!/bin/bash
# create_dmg.sh — Build ClockLock screen saver and package it as a DMG
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$SCRIPT_DIR/ClockLock.xcodeproj"
BUILD_DIR="$SCRIPT_DIR/build"
STAGING_DIR="$BUILD_DIR/dmg_staging"
DMG_PATH="$SCRIPT_DIR/ClockLock.dmg"
VOLUME_NAME="ClockLock Installation"

echo "🕐 Step 1: Cleaning previous build and DMG artifacts..."
rm -f "$DMG_PATH"
rm -rf "$STAGING_DIR"

echo "🕐 Step 2: Building ClockLock screen saver in Release configuration..."
xcodebuild \
  -project "$PROJECT" \
  -target "ClockLock" \
  -configuration Release \
  -arch arm64 \
  build \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR"

echo "🕐 Step 3: Preparing DMG staging directory..."
mkdir -p "$STAGING_DIR"

# Copy the compiled .saver bundle
echo "   Copying ClockLock.saver to staging..."
cp -R "$BUILD_DIR/ClockLock.saver" "$STAGING_DIR/"

# Create symlink to /Library/Screen Savers
echo "   Creating symlink to /Library/Screen Savers..."
ln -s "/Library/Screen Savers" "$STAGING_DIR/Screen Savers"

echo "   Creating symlink to ~/Library/Screen Savers (User-specific)..."
# Note: Finder resolves symlinks in DMG relative to the system running it, but a symlink to
# a relative path like Library/Screen Savers inside the home folder can be tricky.
# We stick to the standard system-wide /Library/Screen Savers symlink, which is universal.

echo "🕐 Step 4: Packaging DMG using hdiutil..."
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "🕐 Step 5: Cleaning up staging directory..."
rm -rf "$STAGING_DIR"

echo "✅ Success! ClockLock.dmg created at:"
echo "   $DMG_PATH"
echo ""
echo "➡️  Double-click ClockLock.dmg to mount it, then drag ClockLock.saver into the Screen Savers shortcut."
