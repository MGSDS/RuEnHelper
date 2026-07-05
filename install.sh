#!/bin/zsh
# Installs RuEnHelper to ~/Applications and registers a LaunchAgent
# so it starts at login.
#
# Usage:
#   ./install.sh              download the latest release from GitHub and install
#   ./install.sh --local      build from source and install
#   ./install.sh --uninstall  remove the app and the LaunchAgent
#
# Standalone install (no repo checkout needed):
#   curl -fsSL https://raw.githubusercontent.com/MGSDS/RuEnHelper/master/install.sh | zsh
set -e

REPO=MGSDS/RuEnHelper
APP_NAME=RuEnHelper
BUNDLE_ID=com.mgsds.ruen-helper
INSTALL_DIR="$HOME/Applications"
APP_PATH="$INSTALL_DIR/$APP_NAME.app"
AGENT_PLIST="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
AGENT_LABEL="$BUNDLE_ID"
DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$APP_NAME.app.zip"

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

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ "$1" == "--local" ]]; then
    cd "$(dirname "$0")"
    ./make-app.sh
    cp -R "$APP_NAME.app" "$TMP_DIR/$APP_NAME.app"
else
    echo "Downloading $DOWNLOAD_URL"
    curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/app.zip"
    ditto -x -k "$TMP_DIR/app.zip" "$TMP_DIR"
    [[ -d "$TMP_DIR/$APP_NAME.app" ]] || { echo "Unexpected archive layout" >&2; exit 1; }
    xattr -dr com.apple.quarantine "$TMP_DIR/$APP_NAME.app" 2>/dev/null || true
fi

# Stop a running instance before replacing the bundle
launchctl bootout "gui/$UID/$AGENT_LABEL" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true

mkdir -p "$INSTALL_DIR"
rm -rf "$APP_PATH"
cp -R "$TMP_DIR/$APP_NAME.app" "$APP_PATH"

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
