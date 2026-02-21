# DockSwitch — Bluetooth Peripheral Switcher Daemon

## Project Goal

A lightweight macOS daemon that automatically switches Magic Keyboard and Magic Trackpad between two Macs (personal and work) when the Apple Studio Display is connected or disconnected.

## Problem Background

Apple Magic peripherals use BLE but do not support multi-device pairing like Logitech MX peripherals. They maintain a single "host" assigned via USB connection. Key findings from investigation:

- Software disconnect is insufficient: puts the trackpad in idle mode, it immediately reconnects to the original host on any input
- The Magic peripherals do NOT advertise over BLE after a software disconnect — confirmed via Core Bluetooth scan
- Removing the pairing record IS the correct primitive: tells the peripheral it has no host, causing it to enter an advertising/pairable state
- Full switching sequence requires remove on the losing machine, then remove+pair+connect on the gaining machine
- No power cycle required if pairing is removed instead of just disconnected

## Switching Sequence

> *Note:* `IOBluetoothDevice.remove()` *is a private API and must be invoked via selector:* `IOBluetoothDevice.perform(Selector("remove"))`

### On dock disconnect (this Mac is losing the peripherals):
Remove pairing records for each peripheral via `IOBluetoothDevice.remove()`.

### On dock connect (this Mac is gaining the peripherals):
For each peripheral:
1. Remove stale pairing record (`IOBluetoothDevice.remove()`)
2. Pair (`IOBluetoothDevicePair.start()`)
3. Connect with retries (`IOBluetoothDevice.openConnection()`)

A retry loop on the connect side is advisable to handle the case where the peripheral hasn't fully entered advertising mode yet.

## Architecture

- **Language**: Swift
- **Deployment**: launchd agent (`~/Library/LaunchAgents/`)
- **USB monitoring**: IOKit `IOServiceAddMatchingNotification` watching for Studio Display vendor/product ID
- **Bluetooth switching**: IOBluetooth framework directly (no external dependencies)
  - `IOBluetoothDevice.remove()` — private API for removing pairing records
  - `IOBluetoothDevicePair` — public API for pairing
  - `IOBluetoothDevice.openConnection()` — public API for connecting
- **No network coordination needed**: each Mac reacts independently to its own dock events

## Configuration

The following values need to be configured per-machine (stored in `~/Library/Preferences/com.dockswitch.plist`):

- `dockVendorID` — Apple Studio Display USB vendor ID: `0x05AC` (1452)
- `dockProductID` — Apple Studio Display USB product ID: `0x1114` (4372)
- `peripheralMACs` — Array of Magic Keyboard / Magic Trackpad MAC addresses

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

- No external dependencies — uses only system frameworks (IOBluetooth, IOKit, Foundation)
- Bluetooth permission granted to the daemon process (System Settings → Privacy & Security → Bluetooth)

## Notes

- No network communication between the two Macs — each machine acts independently
- The daemon should log events to a file for debugging (dock connect/disconnect, pairing attempts, retries)
- IOKit USB matching should use both vendor ID and product ID to avoid false triggers from other USB devices
