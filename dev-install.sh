#!/bin/bash
set -euo pipefail

main() {
    local BINARY_DIR="$HOME/.local/bin"
    local DAEMON_PATH="$BINARY_DIR/dockswitchd"
    local CLI_PATH="$BINARY_DIR/dockswitch"
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

    # Build Swift daemon (universal release binary)
    echo "Building Swift daemon..."
    swift build -c release --arch arm64 --arch x86_64
    echo "Daemon build complete."

    # Sign daemon with Bluetooth entitlement
    echo "Signing daemon..."
    codesign --sign - --entitlements entitlements.plist --force .build/apple/Products/Release/DockSwitchD
    echo "Signed."

    # Build Rust CLI
    echo "Building Rust CLI..."
    cargo build --release --manifest-path cli/Cargo.toml
    echo "CLI build complete."

    # Stop running daemon
    if launchctl list 2>/dev/null | grep -q com.dockswitch; then
        echo "Stopping running daemon..."
        launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
    fi

    # Copy binaries
    mkdir -p "$BINARY_DIR"
    cp .build/apple/Products/Release/DockSwitchD "$DAEMON_PATH"
    chmod +x "$DAEMON_PATH"
    echo "Installed daemon to $DAEMON_PATH"

    cp cli/target/release/dockswitch "$CLI_PATH"
    chmod +x "$CLI_PATH"
    echo "Installed CLI to $CLI_PATH"

    # Restart daemon
    echo "Starting daemon..."
    launchctl load "$LAUNCHD_PLIST"

    # Show versions
    local DAEMON_VERSION CLI_VERSION
    DAEMON_VERSION=$("$DAEMON_PATH" --version 2>/dev/null || echo "unknown")
    CLI_VERSION=$("$CLI_PATH" --version 2>/dev/null || echo "unknown")
    echo ""
    echo "=== DockSwitch dev build installed and running ==="
    echo "Daemon: $DAEMON_VERSION"
    echo "CLI:    $CLI_VERSION"
    echo "Logs:   ~/Library/Logs/DockSwitch.log"
}

main "$@"
