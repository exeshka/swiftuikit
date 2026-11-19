#!/bin/zsh
# Builds and installs the native sheet reference app into the booted simulator.
set -e
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=build/RefSheet.app
rm -rf build; mkdir -p $OUT
xcrun swiftc -target arm64-apple-ios26.0-simulator -sdk "$SDK" -parse-as-library -O main.swift -o $OUT/RefSheet
cat > $OUT/Info.plist <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>RefSheet</string>
<key>CFBundleIdentifier</key><string>com.useravel.refsheet</string>
<key>CFBundleName</key><string>RefSheet</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>MinimumOSVersion</key><string>26.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
<key>UILaunchScreen</key><dict/>
<key>UIRequiredDeviceCapabilities</key><array><string>arm64</string></array>
</dict></plist>
PL
codesign --force --sign - $OUT
xcrun simctl install ${SIM:-booted} $OUT
echo installed
