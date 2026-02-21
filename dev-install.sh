#!/bin/bash
set -euo pipefail

main() {
    local BINARY_DIR="$HOME/.local/bin"
    local BINARY_PATH="$BINARY_DIR/dockswitch"
    local LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.dockswitch.plist"

    # Must be run from repo root
    if [ ! -f "Package.swift" ]; then
        echo "Error: Must be run from the DockSwitch repo root (Package.swift not found)."
        exit 1
    fi

    # Must have a working install already
    if [ ! -f "$LAUNCHD_PLIST" ]; then
        echo "Error: No launchd plist found at $LAUNCHD_PLIST"
        echo "Run install.sh first to set up config and launchd agent."
        exit 1
    fi

    echo "=== DockSwitch Dev Install ==="
    echo ""

    # Build universal release binary
    echo "Building release binary..."
    swift build -c release --arch arm64 --arch x86_64
    echo "Build complete."

    # Sign with Bluetooth entitlement
    echo "Signing binary..."
    codesign --sign - --entitlements entitlements.plist --force .build/apple/Products/Release/DockSwitch
    echo "Signed."

    # Stop running daemon
    if launchctl list 2>/dev/null | grep -q com.dockswitch; then
        echo "Stopping running daemon..."
        launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
    fi

    # Copy binary
    mkdir -p "$BINARY_DIR"
    cp .build/apple/Products/Release/DockSwitch "$BINARY_PATH"
    chmod +x "$BINARY_PATH"
    echo "Installed binary to $BINARY_PATH"

    # Restart daemon
    echo "Starting daemon..."
    launchctl load "$LAUNCHD_PLIST"

    # Show version
    local INSTALLED_VERSION
    INSTALLED_VERSION=$("$BINARY_PATH" --version 2>/dev/null || echo "unknown")
    echo ""
    echo "=== DockSwitch dev build installed and running ==="
    echo "Version: $INSTALLED_VERSION"
    echo "Logs:    ~/Library/Logs/DockSwitch.log"
}

main "$@"
