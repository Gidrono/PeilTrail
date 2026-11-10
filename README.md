# PaleTrail

A tiny macOS menu-bar app that paints a GitHub-style trail of colorful pixel squares behind your cursor while you hold **⌘ Command**.

Inspired by the pixel cursor trail on [github.com](https://github.com/).

## Features

- Hold ⌘ and move the mouse to leave a trail of grid-snapped squares in GitHub's green, blue, purple and pink.
- Squares fade and shrink after ~600 ms, with small "sparkle" squares scattered around the path.
- Works on every display and Space, including full-screen apps.
- Click-through overlay: it never steals clicks or focus.
- Zero CPU when idle: fades are driven by Core Animation, and there is no frame loop.
- Menu-bar toggle for Enabled and Launch at Login.

## Requirements

- macOS 13 Ventura or later
- Xcode command line tools / Swift 5.9+

## Build and run

```bash
git clone https://github.com/Gidrono/paletrail.git
cd paletrail

# quick dev run
swift run

# or build a proper app bundle
./scripts/bundle.sh
open build/PaleTrail.app
```

To install, copy `build/PaleTrail.app` to `/Applications`. Launch at Login only works when running from the app bundle.

## Permissions

PaleTrail only observes mouse movement and modifier-key state. It doesn't read key presses, so it normally needs no special permissions. If the trail doesn't show up, check **System Settings > Privacy & Security > Accessibility** (and **Input Monitoring**) and allow PaleTrail.

## How it works

| File | Role |
| --- | --- |
| `TrailController.swift` | Global `NSEvent` monitors. While ⌘ is held, it interpolates grid cells between successive cursor positions. |
| `OverlayWindow.swift` | One borderless, transparent, click-through window per screen at screen-saver level. |
| `TrailView.swift` | Spawns a `CALayer` per cell with a fade and shrink animation, and removes it on completion. |
| `AppDelegate.swift` | Menu-bar item, settings, and Launch at Login via `SMAppService`. |

Tweak `gridSize`, `lifetime`, `sparkleChance` in `TrailController.swift` or the colors in `Palette` to make it your own.

## License

[MIT](LICENSE)
