#!/bin/zsh
# Builds a Release Slateflow.app and packages it as a drag-to-install DMG:
# dist/Slateflow-<version>.dmg, a window with the app next to an Applications
# shortcut. Signs ad hoc (no Apple Developer ID), so on other Macs the first
# launch needs System Settings > Privacy & Security > Open Anyway.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Slateflow"
BUILD="build/release"
APP="$BUILD/Build/Products/Release/$APP_NAME.app"
STAGING=""
WORK=""
MOUNT=""

cleanup() {
    [[ -n "$MOUNT" ]] && { hdiutil detach "$MOUNT" -quiet 2>/dev/null || hdiutil detach "$MOUNT" -force -quiet 2>/dev/null || true; }
    [[ -n "$STAGING" ]] && rm -rf "$STAGING"
    [[ -n "$WORK" ]] && rm -rf "$WORK"
}
trap cleanup EXIT

# Build number = commit count, so every release from a newer commit is higher.
BUILD_NUMBER="$(git rev-list --count HEAD)"

echo "▸ Building Release (build $BUILD_NUMBER, Apple silicon + Intel)…"
# CODE_SIGN_IDENTITY=- signs ad hoc but still embeds the sandbox entitlements.
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath "$BUILD" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
    build -quiet
xattr -cr "$APP"
# Xcode's ad hoc signature adds the debugger entitlement (get-task-allow); re-sign
# with the app's own entitlements minus that one.
ENT="$(mktemp)"
codesign -d --entitlements - --xml "$APP" > "$ENT" 2>/dev/null
/usr/libexec/PlistBuddy -c 'Delete :com.apple.security.get-task-allow' "$ENT" 2>/dev/null || true
codesign --force --options runtime --entitlements "$ENT" --sign - "$APP"
rm -f "$ENT"
codesign --verify --deep --strict "$APP"
[[ "$(lipo -archs "$APP/Contents/MacOS/$APP_NAME")" == *x86_64*arm64* || "$(lipo -archs "$APP/Contents/MacOS/$APP_NAME")" == *arm64*x86_64* ]] \
    || { echo "✗ App is not universal" >&2; exit 1; }

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
OUT="dist/$APP_NAME-$VERSION.dmg"

echo "▸ Staging DMG contents…"
STAGING="$(mktemp -d)"
ditto "$APP" "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"
mkdir "$STAGING/.background"
swift Tools/MakeDMGBackground.swift "$STAGING/.background/background.png"

echo "▸ Creating image…"
WORK="$(mktemp -d)"
RW="$WORK/rw.dmg"
hdiutil detach "/Volumes/$APP_NAME" -force 2>/dev/null || true
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -fs HFS+ -format UDRW -ov "$RW" -quiet
MOUNT="$(hdiutil attach "$RW" -nobrowse | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}')"

echo "▸ Arranging window…"
# Best effort: Finder automation needs permission and can hang headless; the DMG
# is valid either way, just without the icon layout.
osascript <<APPLESCRIPT >/dev/null 2>&1 &
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 740, 460}
        set theOptions to the icon view options of container window
        set arrangement of theOptions to not arranged
        set icon size of theOptions to 128
        set background picture of theOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {140, 160}
        set position of item "Applications" of container window to {400, 160}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT
STYLE_PID=$!
for _ in {1..20}; do kill -0 "$STYLE_PID" 2>/dev/null || break; sleep 1; done
if kill -0 "$STYLE_PID" 2>/dev/null; then
    kill -9 "$STYLE_PID" 2>/dev/null || true
    echo "  (window layout timed out; continuing unstyled)"
fi

sync
hdiutil detach "$MOUNT" -quiet || hdiutil detach "$MOUNT" -force -quiet
MOUNT=""

echo "▸ Compressing…"
mkdir -p dist
rm -f "$OUT"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$OUT" -quiet

echo "✓ DMG ready: $OUT"
