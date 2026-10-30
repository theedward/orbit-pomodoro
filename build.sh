#!/bin/zsh
set -eu
cd "$(dirname "$0")"
mkdir -p "Orbit.app/Contents/MacOS" "Orbit.app/Contents/Resources" build
for arch in arm64 x86_64; do
    xcrun swiftc -O -target "$arch-apple-macosx14.0" -module-cache-path "${TMPDIR:-/tmp}/orbit-swift-cache" Sources/TimerEngine.swift Sources/Orbit.swift Sources/ThemeDials.swift -o "build/Orbit-$arch"
done
lipo -create build/Orbit-arm64 build/Orbit-x86_64 -output Orbit.app/Contents/MacOS/Orbit
cp Assets/Orbit.icns Orbit.app/Contents/Resources/Orbit.icns
cat > Orbit.app/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Orbit</string>
<key>CFBundleIdentifier</key><string>studio.orbit.pomodoro</string>
<key>CFBundleName</key><string>Orbit</string>
<key>CFBundleDisplayName</key><string>Orbit</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleIconFile</key><string>Orbit</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
xattr -cr Orbit.app
codesign --force --deep --sign - Orbit.app
echo "Built $(pwd)/Orbit.app"
