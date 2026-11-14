# PeilTrail

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
[![Latest release](https://img.shields.io/github/v/release/Gidrono/PeilTrail)](https://github.com/Gidrono/PeilTrail/releases/latest)

A tiny macOS menu-bar app that paints a trail of colorful pixel squares behind your cursor while you hold **⌘ Command**.

![PeilTrail demo: holding Command and moving the mouse leaves a fading trail of colorful squares](docs/demo.gif)

Inspired by the pixel cursor trail on [github.com](https://github.com/).

## Use cases

Hold ⌘ to point things out on screen: in a Zoom or Meet screen share, a code review, a tutorial recording, or just for fun.

<table>
  <tr>
    <td width="50%"><img src="docs/use-cases/01-screen-share-circle.gif" alt="Circling the repo name, Star button, commit count and description on a GitHub page"></td>
    <td width="50%"><img src="docs/use-cases/02-code-review.gif" alt="Bracketing, circling and underlining lines of Swift code on GitHub"></td>
  </tr>
  <tr>
    <td><b>Screen sharing:</b> circle buttons and text while you talk. <i>Neon palette.</i></td>
    <td><b>Code review:</b> bracket a block, circle a value, underline a line. <i>Ocean palette.</i></td>
  </tr>
  <tr>
    <td><img src="docs/use-cases/03-map-route.gif" alt="Tracing a route along the Seine from the Louvre to the Eiffel Tower on OpenStreetMap"></td>
    <td><img src="docs/use-cases/04-flair.gif" alt="Circling install commands and drawing a heart and a star on a README"></td>
  </tr>
  <tr>
    <td><b>Maps and walkthroughs:</b> trace a route from A to B. <i>Fire palette.</i></td>
    <td><b>Docs and flair:</b> highlight the command to run, then draw a heart. <i>Earthy palette.</i></td>
  </tr>
</table>


## Features

- Hold ⌘ and move the mouse to leave a trail of grid-snapped squares (GitHub's green, blue, purple and pink by default). Let go and the trail fades away.
- Pick from 8 colour palettes in the menu bar: GitHub (default), Earthy, Sunset, Fire, Ocean, Forest, Neon and Pastel.
- Squares fade and shrink after ~600 ms, with small "sparkle" squares scattered around the path.
- Works on every display and Space, including over full-screen apps.
- Click-through overlay: it never steals clicks or focus.
- Zero CPU when idle: Core Animation drives the fades, so there's no frame loop.
- Universal app for Apple Silicon and Intel Macs.
- Menu-bar toggles for **Enabled** and **Launch at Login**.


## Install

### Homebrew (recommended)

```bash
brew install --cask gidrono/tap/peiltrail
open -a PeilTrail
```

A grid icon appears in the menu bar. To update or remove it later:

```bash
brew upgrade --cask peiltrail
brew uninstall --cask peiltrail
```

The cask lives in [Gidrono/homebrew-tap](https://github.com/Gidrono/homebrew-tap).

### Build from source

Requires macOS 13+ and Swift 5.9+.

```bash
git clone https://github.com/Gidrono/PeilTrail.git
cd PeilTrail
./scripts/bundle.sh                     # builds build/PeilTrail.app (universal)
cp -R build/PeilTrail.app /Applications/
open -a PeilTrail
```

To try it without installing, run `swift run` from the repo instead. PeilTrail keeps running until you quit it from the menu bar or press Ctrl-C in Terminal.

### Download the app

Download **[PeilTrail.zip](https://github.com/Gidrono/PeilTrail/releases/latest/download/PeilTrail.zip)** from the [latest release](https://github.com/Gidrono/PeilTrail/releases/latest), unzip it, drag **PeilTrail.app** into **Applications**, and open it. The app is signed and notarized by Apple, so it opens without Gatekeeper warnings.

## Usage

- **Hold ⌘ and move the mouse** to draw the trail. Let go of ⌘ before you click, since many apps treat ⌘-click as a different action.
- Click the grid icon in the menu bar to:
  - toggle **Enabled** on or off,
  - turn on **Launch at Login** (only works when running from `/Applications`),
  - choose a **Palette** (each option shows its colours as a row of squares),
  - **Quit**.
- **Screen sharing:** the trail shows up in Zoom, Meet and screen recordings. Share your whole screen rather than a single window, because the trail is drawn in its own overlay window.

## Permissions

PeilTrail only watches mouse movement and whether ⌘ is held. It never reads what you type, so it usually needs no special permissions. If the trail doesn't show up, open **System Settings > Privacy & Security > Accessibility** (and **Input Monitoring**, if PeilTrail is listed there), allow PeilTrail, and relaunch it.

## Uninstall

If you installed with Homebrew, run `brew uninstall --cask peiltrail` (add `--zap` to also remove its preferences).

Otherwise, quit PeilTrail from the menu bar, turn off Launch at Login if you enabled it, and delete `/Applications/PeilTrail.app`.


## Releasing (maintainers)

With a Developer ID Application certificate in the keychain and a notarytool profile saved via `xcrun notarytool store-credentials peiltrail`:

```bash
VERSION=X.Y.Z ./scripts/bundle.sh --notarize   # signs, notarizes, staples, zips
gh release create vX.Y.Z build/PeilTrail.zip
```

Then bump `version` and `sha256` in the [Homebrew cask](https://github.com/Gidrono/homebrew-tap/blob/main/Casks/peiltrail.rb).


## License

[MIT](LICENSE) © Gidi (Gidrono)
