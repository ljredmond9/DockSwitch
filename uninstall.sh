#!/bin/bash
set -euo pipefail

BINARY_PATH="$HOME/.local/bin/dockswitch"
CONFIG_PLIST="$HOME/Library/Preferences/com.dockswitch.plist"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.dockswitch.plist"
LOG_FILE="$HOME/Library/Logs/DockSwitch.log"

echo "=== DockSwitch Uninstaller ==="
echo ""

# Unload agent
if launchctl list 2>/dev/null | grep -q com.dockswitch; then
    launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
    echo "Unloaded launchd agent"
else
    echo "Launchd agent not loaded (skipping)"
fi

# Remove files
for FILE in "$LAUNCHD_PLIST" "$CONFIG_PLIST" "$BINARY_PATH" "$LOG_FILE"; do
    if [ -f "$FILE" ]; then
        rm "$FILE"
        echo "Removed $FILE"
    fi
done

echo ""
echo "=== DockSwitch uninstalled ==="
