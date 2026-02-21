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

Two binaries, one repo:

- **`dockswitchd`** — Swift daemon (`Sources/DockSwitchD/`), runs as a launchd agent
- **`dockswitch`** — Rust CLI (`cli/`), manages the daemon lifecycle

### Daemon (Swift)
- **USB monitoring**: IOKit `IOServiceAddMatchingNotification` watching for Studio Display vendor/product ID
- **Bluetooth switching**: IOBluetooth framework directly (no external dependencies)
  - `IOBluetoothDevice.remove()` — private API for removing pairing records
  - `IOBluetoothDevicePair` — public API for pairing
  - `IOBluetoothDevice.openConnection()` — public API for connecting
- **No network coordination needed**: each Mac reacts independently to its own dock events

### CLI (Rust)
- Lives in `cli/` with its own `Cargo.toml`
- Uses `clap` for subcommand parsing, no other external dependencies
- Shells out to `launchctl` and `curl` for system operations

## Configuration

The following values need to be configured per-machine (stored in `~/Library/Preferences/com.dockswitch.plist`):

- `dockVendorID` — Apple Studio Display USB vendor ID: `0x05AC` (1452)
- `dockProductID` — Apple Studio Display USB product ID: `0x1114` (4372)
- `peripheralMACs` — Array of Magic Keyboard / Magic Trackpad MAC addresses

## CLI Commands

| Command | Description |
|---|---|
| `dockswitch start` | Start the daemon |
| `dockswitch stop` | Stop the daemon |
| `dockswitch restart` | Restart the daemon |
| `dockswitch status` | Show running/stopped, PID, versions, config |
| `dockswitch logs` | Tail the log file |
| `dockswitch update` | Download latest release from GitHub, replace binaries, restart |
| `dockswitch uninstall` | Stop daemon, remove all files |
| `dockswitch --version` | Show CLI version |

## Deployment

Install both binaries to `~/.local/bin/`:
```bash
curl -fsSL https://raw.githubusercontent.com/ljredmond9/DockSwitch/main/install.sh | bash
```

Day-to-day management:
```bash
dockswitch start       # start daemon
dockswitch stop        # stop daemon
dockswitch status      # check status
dockswitch logs        # tail logs
dockswitch update      # update to latest release
dockswitch uninstall   # remove everything
```

Dev install (from repo root):
```bash
./dev-install.sh       # builds both, installs, restarts daemon
```

## Dependencies

- **Daemon**: No external dependencies — uses only system frameworks (IOBluetooth, IOKit, Foundation)
- **CLI**: `clap` crate for argument parsing; shells out to `curl` for updates
- Bluetooth permission granted to the daemon process (System Settings → Privacy & Security → Bluetooth)

## Notes

- No network communication between the two Macs — each machine acts independently
- The daemon should log events to a file for debugging (dock connect/disconnect, pairing attempts, retries)
- IOKit USB matching should use both vendor ID and product ID to avoid false triggers from other USB devices
