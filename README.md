# PaleTrail

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
[![Latest release](https://img.shields.io/github/v/release/Gidrono/paletrail)](https://github.com/Gidrono/paletrail/releases/latest)

A tiny macOS menu-bar app that paints a GitHub-style trail of colorful pixel squares behind your cursor while you hold **⌘ Command**.

![PaleTrail demo: holding Command and moving the mouse leaves a fading trail of colorful squares](docs/demo.gif)

Inspired by the pixel cursor trail on [github.com](https://github.com/).

## Features

- Hold ⌘ and move the mouse to leave a trail of grid-snapped squares in GitHub's green, blue, purple and pink. Let go and the trail fades away.
- Squares fade and shrink after ~600 ms, with small "sparkle" squares scattered around the path.
- Works on every display and Space, including over full-screen apps.
- Click-through overlay: it never steals clicks or focus.
- Zero CPU when idle: Core Animation drives the fades, so there's no frame loop.
- Universal app for Apple Silicon and Intel Macs.
- Menu-bar toggles for **Enabled** and **Launch at Login**.

## Install

### Option 1: Homebrew (recommended)

```bash
brew install --cask gidrono/tap/paletrail
open /Applications/PaleTrail.app
```

That's it, with no Gatekeeper prompt. To update or remove it later:

```bash
brew upgrade --cask paletrail
brew uninstall --cask paletrail
```

The cask lives in [Gidrono/homebrew-tap](https://github.com/Gidrono/homebrew-tap).

### Option 2: Download the app

1. Download **[PaleTrail.zip](https://github.com/Gidrono/paletrail/releases/latest/download/PaleTrail.zip)** from the [latest release](https://github.com/Gidrono/paletrail/releases/latest).
2. Unzip it and drag **PaleTrail.app** into your **Applications** folder.
3. Open it. A grid icon appears in the menu bar.

PaleTrail isn't notarized by Apple yet, so the first time you open it macOS will say it can't verify the developer. To allow it, do one of these:

- Go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to the PaleTrail message.
- Or run this once in Terminal:

  ```bash
  xattr -dr com.apple.quarantine /Applications/PaleTrail.app
  ```

Or do all of it from Terminal:

```bash
curl -L -o /tmp/PaleTrail.zip https://github.com/Gidrono/paletrail/releases/latest/download/PaleTrail.zip
ditto -x -k /tmp/PaleTrail.zip /Applications
xattr -dr com.apple.quarantine /Applications/PaleTrail.app
open /Applications/PaleTrail.app
```

### Option 3: Build from source

Requires macOS 13+ and Xcode (or the Xcode command line tools) with Swift 5.9+.

```bash
git clone https://github.com/Gidrono/paletrail.git
cd paletrail
./scripts/bundle.sh            # builds build/PaleTrail.app (universal)
cp -R build/PaleTrail.app /Applications/
open /Applications/PaleTrail.app
```

For a quick dev run without bundling, use `swift run`.

## Usage

- **Hold ⌘ and move the mouse** to draw the trail.
- Click the grid icon in the menu bar to:
  - toggle **Enabled** on or off,
  - turn on **Launch at Login** (only works when running from `/Applications`),
  - **Quit**.

## Permissions

PaleTrail only watches mouse movement and whether ⌘ is held. It never reads what you type, so it usually needs no special permissions. If the trail doesn't show up, open **System Settings > Privacy & Security > Accessibility** (and **Input Monitoring**, if PaleTrail is listed there), allow PaleTrail, and relaunch it.

## Uninstall

If you installed with Homebrew, run `brew uninstall --cask paletrail` (add `--zap` to also remove its preferences).

Otherwise, quit PaleTrail from the menu bar, turn off Launch at Login if you enabled it, and delete `/Applications/PaleTrail.app`.

## Customize

All the knobs are plain constants:

| What | Where |
| --- | --- |
| Grid size, trail lifetime, sparkle amount | top of `Sources/PaleTrail/TrailController.swift` |
| Colors | `Palette` in `Sources/PaleTrail/TrailView.swift` |

## How it works

| File | Role |
| --- | --- |
| `TrailController.swift` | Global `NSEvent` monitors. While ⌘ is held, it interpolates grid cells between successive cursor positions so fast moves don't leave gaps. |
| `OverlayWindow.swift` | One borderless, transparent, click-through window per screen, at screen-saver level, on all Spaces. |
| `TrailView.swift` | Spawns a `CALayer` per cell with a fade and shrink animation, and removes it when the animation completes. |
| `AppDelegate.swift` | Menu-bar item, settings, and Launch at Login via `SMAppService`. |

## Contributing

Issues and pull requests are welcome! Ideas: more palettes and trail styles, a settings window, a configurable modifier key.

## License

[MIT](LICENSE) © Gidi (Gidrono)
