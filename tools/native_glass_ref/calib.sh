#!/bin/zsh
# Calibration run: hot restart Flutter (CALIB build), screenshot both, print numeric comparison.
cd "$(dirname "$0")"; D=/private/tmp/claude-501/cmp
echo R > /private/tmp/claude-501/fifo; sleep 9
xcrun simctl launch booted com.useravel.ravelUiKitExample >/dev/null; sleep 2
xcrun simctl io booted screenshot $D/c_flutter.png >/dev/null 2>&1
if [ ! -f $D/c_native.png ] || [ "$1" = native ]; then
  xcrun simctl terminate booted com.useravel.refglass >/dev/null 2>&1; xcrun simctl launch booted com.useravel.refglass calib >/dev/null; sleep 3
  xcrun simctl io booted screenshot $D/c_native.png >/dev/null 2>&1
fi
swift calib.swift $D/c_native.png $D/c_flutter.png ../../example/assets/liquid_test_bg.png
