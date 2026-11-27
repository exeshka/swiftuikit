#!/bin/bash
# usage: tools/record.sh <udid> <name> <seconds>  — records the simulator screen to assets/img/<name>.mp4 (H.264, 1x)
# Start it, then drive the app (tap in the simulator); it stops by itself.
UDID=$1; NAME=$2; SEC=${3:-8}
HERE="$(cd "$(dirname "$0")/.." && pwd)"; RAW=$(mktemp -t rec).mov
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$RAW" & PID=$!
sleep "$SEC"; kill -INT $PID; wait $PID 2>/dev/null
if command -v ffmpeg >/dev/null; then ffmpeg -y -loglevel error -i "$RAW" -vf scale=420:-2 -an -movflags +faststart "$HERE/assets/img/$NAME.mp4"
else cp "$RAW" "$HERE/assets/img/$NAME.mp4"; fi
rm -f "$RAW"
