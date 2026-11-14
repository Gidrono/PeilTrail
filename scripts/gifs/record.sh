#!/usr/bin/env bash
# Records one README GIF: opens URL in a clean Chrome app window, switches the
# PeilTrail palette, replays a driver script while ffmpeg records the screen,
# then crops and converts the capture to an optimized GIF.
#
# Usage: record.sh <steps.json> <url> <palette> <out.gif> <width> <height> [seconds] [fps] [pre-steps.json]
#   width/height are the GIF size in points; the window content is placed at
#   (WIN_X + 10, WIN_Y + TITLEBAR + 10) on screen, which steps.json must match.
#   pre-steps.json (optional) runs before recording starts, e.g. to scroll.
#   Chrome keeps per-site zoom in $PROFILE; run zoom.json once against
#   github.com so it renders at 75% and shows its full desktop layout.
#
# Needs Screen Recording and Accessibility permission for the terminal app,
# and the mouse and keyboard must stay untouched while it runs.

set -euo pipefail

STEPS=$1 URL=$2 PALETTE=$3 OUT=$4 W=$5 H=$6
SECONDS_LONG=${7:-10}
FPS=${8:-20}
PRE=${9:-}

WIN_X=200 WIN_Y=150 TITLEBAR=32 INSET=10
SCALE=2
SCREEN_INDEX=${SCREEN_INDEX:-2}

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-/tmp/peilrec}
PROFILE=$WORK/chrome-profile
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p "$WORK"

[[ -x $WORK/driver && $WORK/driver -nt $HERE/driver.swift ]] || swiftc -O "$HERE/driver.swift" -o "$WORK/driver"

ORIGINAL_PALETTE=$(defaults read com.gidrono.peiltrail PeilTrailPalette 2>/dev/null || echo github)
restart_peiltrail() {
    defaults write com.gidrono.peiltrail PeilTrailPalette "$1"
    osascript -e 'tell application "PeilTrail" to quit' >/dev/null 2>&1 || true
    while pgrep -x PeilTrail >/dev/null; do sleep 0.2; done
    open -a PeilTrail
    sleep 1.5
}
cleanup() {
    pkill -f "user-data-dir=$PROFILE" >/dev/null 2>&1 || true
    restart_peiltrail "$ORIGINAL_PALETTE"
}
trap cleanup EXIT

restart_peiltrail "$PALETTE"

pkill -f "user-data-dir=$PROFILE" >/dev/null 2>&1 || true
sleep 0.5
"$CHROME" --user-data-dir="$PROFILE" --no-first-run --no-default-browser-check \
    --disable-features=Translate,ChromeWhatsNewUI --hide-crash-restore-bubble \
    --app="$URL" --window-position=$WIN_X,$WIN_Y \
    --window-size=$((W + 2 * INSET)),$((H + 2 * INSET + TITLEBAR)) >"$WORK/chrome.log" 2>&1 &
sleep 6

[[ -n $PRE ]] && "$WORK/driver" "$PRE" && sleep 1

RAW=$WORK/$(basename "$OUT" .gif).mov
ffmpeg -hide_banner -v error -y -f avfoundation -capture_cursor 1 -framerate 30 \
    -pixel_format bgr0 -i "$SCREEN_INDEX:none" -t "$SECONDS_LONG" \
    -c:v libx264 -preset ultrafast -crf 0 "$RAW" 2>/dev/null &
FFMPEG=$!
sleep 0.6
"$WORK/driver" "$STEPS"
wait $FFMPEG

CROP="crop=$((W * SCALE)):$((H * SCALE)):$(((WIN_X + INSET) * SCALE)):$(((WIN_Y + TITLEBAR + INSET) * SCALE))"
FILTERS="$CROP,fps=$FPS,scale=$W:$H:flags=lanczos"
ffmpeg -hide_banner -v error -y -ss 0.3 -i "$RAW" \
    -vf "$FILTERS,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
    -loop 0 "$OUT"

echo "$OUT: $(($(stat -f%z "$OUT") / 1024)) KB"
