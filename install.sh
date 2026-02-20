#!/bin/bash
set -euo pipefail

REPO="ljredmond9/DockSwitch"
BINARY_NAME="dockswitch-macos-universal"
BINARY_DIR="$HOME/.local/bin"
BINARY_PATH="$BINARY_DIR/dockswitch"
CONFIG_PLIST="$HOME/Library/Preferences/com.dockswitch.plist"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.dockswitch.plist"

echo "=== DockSwitch Installer ==="
echo ""

# Check prerequisites
BLUEUTIL_PATH="/opt/homebrew/bin/blueutil"
if [ ! -x "$BLUEUTIL_PATH" ]; then
    BLUEUTIL_PATH=$(command -v blueutil 2>/dev/null || true)
    if [ -z "$BLUEUTIL_PATH" ]; then
        echo "Error: blueutil not found. Install with: brew install blueutil"
        exit 1
    fi
fi
echo "Found blueutil at $BLUEUTIL_PATH"

# Download latest binary
echo ""
echo "Downloading latest DockSwitch binary..."
DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$BINARY_NAME"
mkdir -p "$BINARY_DIR"
if ! curl -fSL --progress-bar -o "$BINARY_PATH" "$DOWNLOAD_URL"; then
    echo "Error: Failed to download binary from $DOWNLOAD_URL"
    echo "Check that a release exists at https://github.com/$REPO/releases"
    exit 1
fi
chmod +x "$BINARY_PATH"
echo "Installed binary to $BINARY_PATH"

# Show version
INSTALLED_VERSION=$("$BINARY_PATH" --version 2>/dev/null || echo "unknown")
echo "Version: $INSTALLED_VERSION"

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

    read -rp "Dock vendor ID [1452]: " VENDOR_ID
    VENDOR_ID="${VENDOR_ID:-1452}"

    read -rp "Dock product ID [4372]: " PRODUCT_ID
    PRODUCT_ID="${PRODUCT_ID:-4372}"

    echo ""
    echo "--- Bluetooth peripherals ---"
    echo "To find MAC addresses, run:"
    echo "  $BLUEUTIL_PATH --paired"
    echo ""

    PERIPHERAL_MACS=()
    while true; do
        read -rp "Peripheral MAC address (or empty to finish): " MAC
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
    echo "  blueutil:     $BLUEUTIL_PATH"
    echo ""
    read -rp "Proceed with install? [Y/n]: " CONFIRM
    CONFIRM="${CONFIRM:-Y}"
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    # Write config plist
    MACS_XML=""
    for MAC in "${PERIPHERAL_MACS[@]}"; do
        MACS_XML+="		<string>$MAC</string>
"
    done

    cat > "$CONFIG_PLIST" << EOF
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
	<key>bleutilPath</key>
	<string>$BLUEUTIL_PATH</string>
</dict>
</plist>
EOF
    echo "Wrote config to $CONFIG_PLIST"
fi

# Unload existing agent if present
if launchctl list 2>/dev/null | grep -q com.dockswitch; then
    launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
fi

# Write launchd plist
mkdir -p "$(dirname "$LAUNCHD_PLIST")"
cat > "$LAUNCHD_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.dockswitch</string>
	<key>ProgramArguments</key>
	<array>
		<string>$BINARY_PATH</string>
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
EOF
echo "Wrote launchd plist to $LAUNCHD_PLIST"

# Load agent
launchctl load "$LAUNCHD_PLIST"
echo "Loaded launchd agent"

echo ""
echo "=== DockSwitch installed and running ==="
echo "Logs: ~/Library/Logs/DockSwitch.log"
echo "To uninstall: curl -fsSL https://raw.githubusercontent.com/$REPO/main/uninstall.sh | bash"
