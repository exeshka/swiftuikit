#!/bin/bash
# Screenshots of the example app screens on a booted iOS simulator -> assets/img/<name>-<dark|light>.jpg
# usage: tools/capture.sh <udid> <screen[:name]>...   (needs `flutter build ios --simulator --debug` in example_ui_kit first)
set -e
UDID=$1; shift
BID=com.useravel.ravelUiKitExample
HERE="$(cd "$(dirname "$0")/.." && pwd)"
APP="$HERE/../../example_ui_kit/build/ios/iphonesimulator/Runner.app"
xcrun simctl install "$UDID" "$APP"
for spec in "$@"; do
  screen=${spec%%:*}; name=${spec##*:}
  for theme in dark light; do
    xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
    DATA=$(xcrun simctl get_app_container "$UDID" $BID data)
    printf 'SCREEN=%s\nTHEME=%s\n' "$screen" "$theme" > "$DATA/tmp/launch.txt"
    xcrun simctl launch "$UDID" $BID >/dev/null
    sleep ${WAIT:-4}
    raw=$(mktemp -t shot).png
    xcrun simctl io "$UDID" screenshot "$raw" >/dev/null 2>&1
    sips -Z 760 -s format jpeg -s formatOptions 82 "$raw" --out "$HERE/assets/img/$name-$theme.jpg" >/dev/null
    rm -f "$raw"
  done
  echo "captured $name"
done
