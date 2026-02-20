# DockSwitch — Bluetooth Peripheral Switcher Daemon

## Project Goal

A lightweight macOS daemon that automatically switches Magic Keyboard and Magic Trackpad between two Macs (personal and work) when the Apple Studio Display is connected or disconnected.

## Problem Background

Apple Magic peripherals use BLE but do not support multi-device pairing like Logitech MX peripherals. They maintain a single "host" assigned via USB connection. Key findings from investigation:

- `blueutil --disconnect` is insufficient: puts the trackpad in idle mode, it immediately reconnects to the original host on any input
- The Magic peripherals do NOT advertise over BLE after a software disconnect — confirmed via Core Bluetooth scan
- `blueutil --unpair` IS the correct primitive: tells the peripheral it has no host, causing it to enter an advertising/pairable state
- Full switching sequence requires unpair on the losing machine, then unpair+pair+connect on the gaining machine
- No power cycle required if `--unpair` is used instead of `--disconnect`

## Switching Sequence

### On dock disconnect (this Mac is losing the peripherals):
```bash
blueutil --unpair <keyboard-mac>
blueutil --unpair <trackpad-mac>
```

### On dock connect (this Mac is gaining the peripherals):
```bash
blueutil --unpair <keyboard-mac>        # clear any stale pairing record
blueutil --pair <keyboard-mac>
blueutil --connect <keyboard-mac>
blueutil --unpair <trackpad-mac>
blueutil --pair <trackpad-mac>
blueutil --connect <trackpad-mac>
```

A retry loop on the connect side is advisable to handle the case where the peripheral hasn't fully entered advertising mode yet.

## Architecture

- **Language**: Swift
- **Deployment**: launchd agent (`~/Library/LaunchAgents/`)
- **USB monitoring**: IOKit `IOServiceAddMatchingNotification` watching for Studio Display vendor/product ID
- **Bluetooth switching**: Shell out to `blueutil` (expected at `/opt/homebrew/bin/blueutil`)
- **No network coordination needed**: each Mac reacts independently to its own dock events

## Configuration

The following values need to be configured per-machine (store in a plist or hardcoded constants):

- `DOCK_VENDOR_ID` — Apple Studio Display USB vendor ID: `0x05AC` (1452)
- `DOCK_PRODUCT_ID` — Apple Studio Display USB product ID: `0x1114` (4372)
- `KEYBOARD_MAC` — Magic Keyboard MAC address (get via `blueutil --paired`)
- `TRACKPAD_MAC` — Magic Trackpad MAC address (get via `blueutil --paired`)
- `BLUEUTIL_PATH` — default `/opt/homebrew/bin/blueutil`

## Getting Device IDs

```bash
# Studio Display IDs (already known):
# vendorID=0x05AC (1452), productID=0x1114 (4372)

# Get keyboard and trackpad MAC addresses
blueutil --paired
```

## Deployment

Install as a launchd agent so it starts at login and runs in the background:

```bash
cp com.dockswitch.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.dockswitch.plist
```

Uninstall:
```bash
launchctl unload ~/Library/LaunchAgents/com.dockswitch.plist
rm ~/Library/LaunchAgents/com.dockswitch.plist
```

## Dependencies

- `blueutil` — install via `brew install blueutil`
- Bluetooth permission granted to the terminal/daemon process (System Settings → Privacy & Security → Bluetooth)

## Notes

- No network communication between the two Macs — each machine acts independently
- The daemon should log events to a file for debugging (dock connect/disconnect, pairing attempts, retries)
- Both Macs run the same binary with different config values
- IOKit USB matching should use both vendor ID and product ID to avoid false triggers from other USB devices
