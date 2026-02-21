#!/bin/bash
set -euo pipefail

main() {
    local REPO="ljredmond9/DockSwitch"
    local BINARY_DIR="$HOME/.local/bin"
    local DAEMON_PATH="$BINARY_DIR/dockswitchd"
    local CLI_PATH="$BINARY_DIR/dockswitch"
    local CONFIG_PLIST="$HOME/Library/Preferences/com.dockswitch.plist"
    local LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.dockswitch.plist"

    echo "=== DockSwitch Installer ==="
    echo ""

    # Download latest binaries
    mkdir -p "$BINARY_DIR"

    echo "Downloading latest DockSwitch daemon..."
    local DAEMON_URL="https://github.com/$REPO/releases/latest/download/dockswitchd-macos-universal"
    if ! curl -fSL --progress-bar -o "$DAEMON_PATH" "$DAEMON_URL"; then
        echo "Error: Failed to download daemon from $DAEMON_URL"
        echo "Check that a release exists at https://github.com/$REPO/releases"
        exit 1
    fi
    chmod +x "$DAEMON_PATH"
    echo "Installed daemon to $DAEMON_PATH"

    echo "Downloading latest DockSwitch CLI..."
    local CLI_URL="https://github.com/$REPO/releases/latest/download/dockswitch-macos-universal"
    if ! curl -fSL --progress-bar -o "$CLI_PATH" "$CLI_URL"; then
        echo "Error: Failed to download CLI from $CLI_URL"
        exit 1
    fi
    chmod +x "$CLI_PATH"
    echo "Installed CLI to $CLI_PATH"

    # Show version
    local DAEMON_VERSION CLI_VERSION
    DAEMON_VERSION=$("$DAEMON_PATH" --version 2>/dev/null || echo "unknown")
    CLI_VERSION=$("$CLI_PATH" --version 2>/dev/null || echo "unknown")
    echo "Daemon: $DAEMON_VERSION"
    echo "CLI:    $CLI_VERSION"

    # Config — skip prompts if config already exists (upgrade-safe)
    if [ -f "$CONFIG_PLIST" ]; then
        echo ""
        echo "Existing config found at $CONFIG_PLIST — keeping it."
    else
        echo ""
        echo "--- Host device (dock/display) ---"
        echo "To find your device IDs, run:"
        echo "  ioreg -p IOUSB -l | grep -A5 'idVendor\\|idProduct'"
        echo ""
        echo "Apple Studio Display defaults: vendorID=1452 productID=4372"
        echo ""

        local VENDOR_ID PRODUCT_ID
        read -rp "Dock vendor ID [1452]: " VENDOR_ID < /dev/tty
        VENDOR_ID="${VENDOR_ID:-1452}"

        read -rp "Dock product ID [4372]: " PRODUCT_ID < /dev/tty
        PRODUCT_ID="${PRODUCT_ID:-4372}"

        echo ""
        echo "--- Bluetooth peripherals ---"
        echo "To find MAC addresses, open System Settings > Bluetooth,"
        echo "or run: system_profiler SPBluetoothDataType"
        echo ""

        local PERIPHERAL_MACS=()
        local MAC
        while true; do
            read -rp "Peripheral MAC address (or empty to finish): " MAC < /dev/tty
            [ -z "$MAC" ] && break
            PERIPHERAL_MACS+=("$MAC")
        done

        if [ ${#PERIPHERAL_MACS[@]} -eq 0 ]; then
            echo "Error: At least one peripheral MAC address is required."
            exit 1
        fi

        echo ""
        echo "Configuration:"
        echo "  Vendor ID:    $VENDOR_ID"
        echo "  Product ID:   $PRODUCT_ID"
        echo "  Peripherals:  ${PERIPHERAL_MACS[*]}"
        echo ""
        local CONFIRM
        read -rp "Proceed with install? [Y/n]: " CONFIRM < /dev/tty
        CONFIRM="${CONFIRM:-Y}"
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi

        # Write config plist
        local MACS_XML=""
        for MAC in "${PERIPHERAL_MACS[@]}"; do
            MACS_XML+="		<string>$MAC</string>
"
        done

        cat > "$CONFIG_PLIST" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>dockVendorID</key>
	<integer>$VENDOR_ID</integer>
	<key>dockProductID</key>
	<integer>$PRODUCT_ID</integer>
	<key>peripheralMACs</key>
	<array>
$MACS_XML	</array>
</dict>
</plist>
PLISTEOF
        echo "Wrote config to $CONFIG_PLIST"
    fi

    # Unload existing agent if present
    if launchctl list 2>/dev/null | grep -q com.dockswitch; then
        launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
    fi

    # Write launchd plist
    mkdir -p "$(dirname "$LAUNCHD_PLIST")"
    cat > "$LAUNCHD_PLIST" << LAUNCHDEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.dockswitch</string>
	<key>ProgramArguments</key>
	<array>
		<string>$DAEMON_PATH</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>StandardOutPath</key>
	<string>$HOME/Library/Logs/DockSwitch.log</string>
	<key>StandardErrorPath</key>
	<string>$HOME/Library/Logs/DockSwitch.log</string>
</dict>
</plist>
LAUNCHDEOF
    echo "Wrote launchd plist to $LAUNCHD_PLIST"

    # Load agent
    launchctl load "$LAUNCHD_PLIST"
    echo "Loaded launchd agent"

    echo ""
    echo "=== DockSwitch installed and running ==="
    echo "Manage with: dockswitch status | start | stop | logs"
    echo "To uninstall: dockswitch uninstall"
}

main "$@"
