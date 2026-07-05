#!/bin/zsh
# Builds RuEnHelper.app in the project directory.
set -e
cd "$(dirname "$0")"

swift build -c release

APP=RuEnHelper.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/RuEnHelper "$APP/Contents/MacOS/RuEnHelper"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.mgsds.ruen-helper</string>
    <key>CFBundleName</key>
    <string>RuEnHelper</string>
    <key>CFBundleExecutable</key>
    <string>RuEnHelper</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --sign - "$APP"
echo "Built $APP"
