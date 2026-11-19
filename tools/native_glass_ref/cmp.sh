#!/bin/zsh
# Hot-restarts the running `flutter run` (fifo), screenshots Flutter and native, prints the comparison.
# usage: cmp.sh <tag>
cd "$(dirname "$0")"
T=${1:-x}; D=/private/tmp/claude-501/cmp
echo R > /private/tmp/claude-501/fifo; sleep 9
xcrun simctl launch booted com.useravel.ravelUiKitExample >/dev/null; sleep 2
xcrun simctl io booted screenshot $D/flutter_$T.png >/dev/null 2>&1
xcrun simctl terminate booted com.useravel.refglass >/dev/null 2>&1; xcrun simctl launch booted com.useravel.refglass >/dev/null; sleep 2
xcrun simctl io booted screenshot $D/native_$T.png >/dev/null 2>&1
swift compare.swift $D/native_$T.png $D/flutter_$T.png ../../example/assets/liquid_bg.png $D/out_$T.png
