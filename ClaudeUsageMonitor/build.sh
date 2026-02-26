#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="ClaudeUsageMonitor"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"

echo "==> Building $APP_NAME (release)..."
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"

# Copy Info.plist
cp Resources/Info.plist "$CONTENTS/Info.plist"

echo "==> Done! App bundle at: $APP_BUNDLE"
echo "    Run with: open $APP_BUNDLE"
