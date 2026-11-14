# Mac App Store submission

PeilTrail’s Homebrew / Developer ID build stays unsigned for sandbox. This file lists the remaining **manual** steps to ship a sandboxed Mac App Store build. Signing and App Store Connect setup are intentionally not automated here.

## Already in the repo

- Sandbox-friendly input: polling `NSEvent.modifierFlags` / `NSEvent.mouseLocation` instead of a global event monitor (no Accessibility TCC prompt).
- `PeilTrail.entitlements` with `com.apple.security.app-sandbox = true` (use for the App Store archive only; `scripts/bundle.sh` does not apply it).
- `LSApplicationCategoryType = public.app-category.utilities` in the generated `Info.plist`.
- App icon (`Resources/AppIcon.icns`, `CFBundleIconFile` / asset catalog source under `Sources/PeilTrail/Assets.xcassets`).

## Manual steps

1. **Apple Distribution certificate**  
   Create or reuse an “Apple Distribution” certificate in your Apple Developer account / Keychain (not Developer ID Application).

2. **Mac App Store provisioning profile**  
   Create a Mac App Store App ID matching `com.gidrono.peiltrail`, enable App Sandbox, and download a Mac App Store provisioning profile that includes your distribution certificate.

3. **App Store Connect record**  
   Create the PeilTrail app record (bundle ID `com.gidrono.peiltrail`), pricing, age rating, and metadata. You’ll need a **privacy policy URL** before submission.

4. **Archive and upload**  
   Either:
   - Open / generate an Xcode project that links `PeilTrail.entitlements`, uses the App Store signing identity + profile, then **Product → Archive** and upload via the Organizer, or
   - Build a sandboxed `.app` (codesign with `--entitlements PeilTrail.entitlements` and the Apple Distribution identity), then upload with **Transporter** / `xcrun altool` / `notarytool`-adjacent App Store upload tooling as appropriate for your workflow.

   Do **not** use `scripts/bundle.sh --notarize` for the store build; that path targets Developer ID + notarization for direct download / Homebrew.

5. **Screenshots**  
   Provide Mac screenshots at **16:10** (e.g. 1280×800 or 2560×1600) showing the trail in use. Capture on a real Mac; the overlay is menu-bar / full-screen UI.

6. **Privacy policy URL**  
   Host a short privacy policy (PeilTrail does not collect personal data; it only reads modifier flags and mouse location locally) and paste the URL into App Store Connect.

## Notes

- Launch at Login (`SMAppService`) may need extra review or entitlement consideration depending on current App Store rules; verify at submission time.
- Full-screen overlay behavior under the sandbox (`.screenSaver` level, `fullScreenAuxiliary`) should be smoke-tested on a Mac before submitting.
