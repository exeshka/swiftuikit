#!/bin/zsh
# Builds and installs the native glass reference app into the booted simulator.
set -e
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=build/RefGlass.app
rm -rf build; mkdir -p $OUT
xcrun swiftc -target arm64-apple-ios26.0-simulator -sdk "$SDK" -parse-as-library -O main.swift -o $OUT/RefGlass
cp ../../example/assets/liquid_bg.png $OUT/bg.png
cp ../../example/assets/liquid_test_bg.png $OUT/calib.png
cp ../../example/assets/liquid_adapt_bg.png $OUT/adapt.png
cat > $OUT/Info.plist <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>RefGlass</string>
<key>CFBundleIdentifier</key><string>com.useravel.refglass</string>
<key>CFBundleName</key><string>RefGlass</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>MinimumOSVersion</key><string>26.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
<key>UILaunchScreen</key><dict/>
<key>UIRequiredDeviceCapabilities</key><array><string>arm64</string></array>
</dict></plist>
PL
codesign --force --sign - $OUT
xcrun simctl install booted $OUT
echo installed
