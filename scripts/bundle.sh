#!/usr/bin/env bash
# Builds a universal (Apple Silicon + Intel) PaleTrail.app into build/.
# Pass --zip to also produce build/PaleTrail.zip for releases.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.1.0}"
APP="build/PaleTrail.app"
ARCHS=(--arch arm64 --arch x86_64)

swift build -c release "${ARCHS[@]}"
BIN_DIR="$(swift build -c release "${ARCHS[@]}" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/PaleTrail" "$APP/Contents/MacOS/PaleTrail"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>PaleTrail</string>
    <key>CFBundleDisplayName</key>
    <string>PaleTrail</string>
    <key>CFBundleIdentifier</key>
    <string>com.gidrono.paletrail</string>
    <key>CFBundleExecutable</key>
    <string>PaleTrail</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"

echo "Built $APP"

if [[ "${1:-}" == "--zip" ]]; then
    ZIP="build/PaleTrail.zip"
    rm -f "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
    echo "Built $ZIP"
fi
