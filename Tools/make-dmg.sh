#!/bin/zsh
# Release pipeline: builds a Release Slateflow.app signed with Developer ID
# (hardened runtime), packages it as dist/Slateflow-<version>.dmg (the app next
# to an Applications shortcut), signs, notarizes and staples the DMG, then adds
# it to the Sparkle feed ($APPCAST, docs/appcast.xml by default). The release
# workflow publishes the feed to the gh-pages branch, which GitHub Pages serves.
#
# Needs the Developer ID Application certificate in a keychain. On the maintainer's
# Mac the notarytool profile "slateflow-notary" and Sparkle's EdDSA key (login
# keychain, account "slateflow") are used; the release workflow passes them as
# files instead: NOTARY_KEY_PATH + NOTARY_KEY_ID + NOTARY_ISSUER_ID, and
# SPARKLE_KEY_FILE. APPCAST overrides the feed path. Nothing is pushed or
# uploaded; see docs/RELEASING.md.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Slateflow"
IDENTITY="Developer ID Application: Sk Ashifali Shaikh (GG4G6A42SB)"
TEAM_ID="GG4G6A42SB"
NOTARY_PROFILE="slateflow-notary"
SPARKLE_ACCOUNT="slateflow"
REPO_URL="https://github.com/PixelEtch/Slateflow"
APPCAST="${APPCAST:-docs/appcast.xml}"
BUILD="build/release"
if [[ -n "${NOTARY_KEY_PATH:-}" ]]; then
    NOTARY_AUTH=(--key "$NOTARY_KEY_PATH" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID")
else
    NOTARY_AUTH=(--keychain-profile "$NOTARY_PROFILE")
fi
if [[ -n "${SPARKLE_KEY_FILE:-}" ]]; then
    SPARKLE_AUTH=(--ed-key-file "$SPARKLE_KEY_FILE")
else
    SPARKLE_AUTH=(--account "$SPARKLE_ACCOUNT")
fi
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
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath "$BUILD" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM="$TEAM_ID" \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    build -quiet
xattr -cr "$APP"

echo "▸ Signing with Developer ID…"
# Sparkle's helpers ship ad hoc signed; notarization needs every nested binary
# signed with our identity, hardened runtime and a timestamp, inside out.
sign() { codesign --force --timestamp --options runtime --sign "$IDENTITY" "$@"; }
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
sign "$SPARKLE/XPCServices/Installer.xpc"
sign --preserve-metadata=entitlements "$SPARKLE/XPCServices/Downloader.xpc"
sign "$SPARKLE/Autoupdate"
sign "$SPARKLE/Updater.app"
sign "$APP/Contents/Frameworks/Sparkle.framework"
# Re-sign the app with its own entitlements, minus the debugger one if present.
ENT="$(mktemp)"
codesign -d --entitlements - --xml "$APP" > "$ENT" 2>/dev/null
/usr/libexec/PlistBuddy -c 'Delete :com.apple.security.get-task-allow' "$ENT" 2>/dev/null || true
sign --entitlements "$ENT" "$APP"
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
# The mounted disk shows the app icon instead of a generic one.
cp "$APP/Contents/Resources/$APP_NAME.icns" "$STAGING/.VolumeIcon.icns"
mkdir "$STAGING/.background"
swift Tools/MakeDMGBackground.swift "$STAGING/.background/background.png"

echo "▸ Creating image…"
WORK="$(mktemp -d)"
RW="$WORK/rw.dmg"
hdiutil detach "/Volumes/$APP_NAME" -force 2>/dev/null || true
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -fs HFS+ -format UDRW -ov "$RW" -quiet
MOUNT="$(hdiutil attach "$RW" -nobrowse | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}')"
SetFile -a C "$MOUNT"   # use .VolumeIcon.icns as the volume's icon

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
codesign --force --timestamp --sign "$IDENTITY" "$OUT"

echo "▸ Notarizing (usually a few minutes)…"
RESULT="$(xcrun notarytool submit "$OUT" "${NOTARY_AUTH[@]}" --wait --output-format json)"
if [[ "$(jq -r .status <<<"$RESULT")" != "Accepted" ]]; then
    echo "✗ Notarization failed: $RESULT" >&2
    xcrun notarytool log "$(jq -r .id <<<"$RESULT")" "${NOTARY_AUTH[@]}" >&2 || true
    exit 1
fi
xcrun stapler staple "$OUT"
spctl -a -vv -t install "$OUT"

echo "▸ Updating appcast…"
# generate_appcast comes with the Sparkle package, resolved into the build folder.
GENERATE_APPCAST="$BUILD/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast"
[[ -x "$GENERATE_APPCAST" ]] || { echo "✗ Missing $GENERATE_APPCAST" >&2; exit 1; }
# Run on a folder holding only this DMG plus the current feed, so the download
# prefix (one tag per release) applies to the new item and older items stay as they are.
FEED="$WORK/feed"
mkdir -p "$FEED" "$(dirname "$APPCAST")"
cp "$OUT" "$FEED/"
[[ -f "$APPCAST" ]] && cp "$APPCAST" "$FEED/appcast.xml"
"$GENERATE_APPCAST" "${SPARKLE_AUTH[@]}" \
    --download-url-prefix "$REPO_URL/releases/download/v$VERSION/" \
    --link "$REPO_URL/releases" --maximum-versions 0 "$FEED"
cp "$FEED/appcast.xml" "$APPCAST"

echo "✓ Notarized DMG: $PWD/$OUT"
echo "✓ Appcast:       $PWD/$APPCAST"
echo "  Next (Mac releases only): create GitHub release v$VERSION with the DMG, then put $APPCAST on gh-pages as appcast.xml."
