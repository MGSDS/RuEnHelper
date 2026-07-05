#!/bin/zsh
# Installs RuEnHelper: builds the app, copies it to ~/Applications,
# and registers a LaunchAgent so it starts at login.
# Usage: ./install.sh | ./install.sh --uninstall
set -e
cd "$(dirname "$0")"

APP_NAME=RuEnHelper
BUNDLE_ID=com.mgsds.ruen-helper
INSTALL_DIR="$HOME/Applications"
APP_PATH="$INSTALL_DIR/$APP_NAME.app"
AGENT_PLIST="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
AGENT_LABEL="$BUNDLE_ID"

uninstall() {
    launchctl bootout "gui/$UID/$AGENT_LABEL" 2>/dev/null || true
    pkill -x "$APP_NAME" 2>/dev/null || true
    rm -f "$AGENT_PLIST"
    rm -rf "$APP_PATH"
    echo "Uninstalled."
}

if [[ "$1" == "--uninstall" ]]; then
    uninstall
    exit 0
fi

./make-app.sh

# Stop a running instance before replacing the bundle
launchctl bootout "gui/$UID/$AGENT_LABEL" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true

mkdir -p "$INSTALL_DIR"
rm -rf "$APP_PATH"
cp -R "$APP_NAME.app" "$APP_PATH"

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$AGENT_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_PATH/Contents/MacOS/$APP_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$UID" "$AGENT_PLIST"

sleep 1
if pgrep -xq "$APP_NAME"; then
    echo "Installed and running: Ctrl+Shift+1 -> EN, Ctrl+Shift+2 -> RU"
    echo "Starts automatically at login. Uninstall: ./install.sh --uninstall"
else
    echo "Installed, but the process is not running. Check: launchctl print gui/$UID/$AGENT_LABEL" >&2
    exit 1
fi
