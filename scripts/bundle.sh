#!/usr/bin/env bash
# Builds a universal (Apple Silicon + Intel) PeilTrail.app into build/.
#
#   ./scripts/bundle.sh              build and sign the app
#   ./scripts/bundle.sh --zip        also produce build/PeilTrail.zip
#   ./scripts/bundle.sh --notarize   zip, notarize with Apple and staple the ticket
#
# Signing uses the first "Developer ID Application" identity in the keychain,
# or SIGN_IDENTITY if set. Without one, the app is ad-hoc signed (local use only).
# Notarizing needs a notarytool keychain profile (NOTARY_PROFILE, default
# "peiltrail"), created once with `xcrun notarytool store-credentials`.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.2.0}"
APP="build/PeilTrail.app"
ZIP="build/PeilTrail.zip"
ARCHS=(arm64 x86_64)
NOTARY_PROFILE="${NOTARY_PROFILE:-peiltrail}"
MODE="${1:-}"

if [[ -z "${SIGN_IDENTITY:-}" ]]; then
    SIGN_IDENTITY="$(security find-identity -v -p codesigning \
        | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -n 1)"
fi
if [[ "$MODE" == "--notarize" && -z "$SIGN_IDENTITY" ]]; then
    echo "error: --notarize needs a Developer ID Application certificate in the keychain" >&2
    exit 1
fi

# One build per arch, merged with lipo: passing several --arch flags to a single
# `swift build` needs xcbuild, which only ships with full Xcode.
BINARIES=()
for arch in "${ARCHS[@]}"; do
    swift build -c release --arch "$arch"
    BINARIES+=("$(swift build -c release --arch "$arch" --show-bin-path)/PeilTrail")
done

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create -output "$APP/Contents/MacOS/PeilTrail" "${BINARIES[@]}"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>PeilTrail</string>
    <key>CFBundleDisplayName</key>
    <string>PeilTrail</string>
    <key>CFBundleIdentifier</key>
    <string>com.gidrono.peiltrail</string>
    <key>CFBundleExecutable</key>
    <string>PeilTrail</string>
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

if [[ -n "$SIGN_IDENTITY" ]]; then
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
    echo "Signed with: $SIGN_IDENTITY"
else
    codesign --force --sign - "$APP"
    echo "warning: no Developer ID certificate found, ad-hoc signed (local use only)" >&2
fi
codesign --verify --strict "$APP"

echo "Built $APP"

make_zip() {
    rm -f "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
}

case "$MODE" in
    --zip)
        make_zip
        echo "Built $ZIP"
        ;;
    --notarize)
        make_zip
        xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
        xcrun stapler staple "$APP"
        # Re-zip so the download carries the stapled ticket.
        make_zip
        spctl --assess --type execute --verbose=2 "$APP"
        echo "Notarized $ZIP"
        ;;
esac
