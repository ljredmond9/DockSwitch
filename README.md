# dockswitch

A lightweight tool for macOS that automatically connects/disconnects Bluetooth devices based on USB device connect/disconnect events (e.g., docking/undocking from a display or Thunderbolt dock). Includes a LaunchAgent for detecting USB events and managing Bluetooth devices, and a CLI tool for managing the daemon.

## Why

Some Bluetooth peripherals don't support multi-device pairing — they bind to a single host and won't advertise to other devices after a software disconnect. If you dock/undock between two machines, you're stuck manually re-pairing every time.

dockswitch solves this by watching for a USB device (like a dock or display) and automatically managing Bluetooth pairing records. When the USB device disconnects, pairing records are removed so peripherals enter advertising mode. When it connects, peripherals are paired and connected with retries.

No power cycling, no manual re-pairing, no network coordination between machines. Each Mac runs the daemon independently and reacts to its own USB events.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ljredmond9/dockswitch/main/install.sh | bash
```

The installer downloads both binaries to `~/.local/bin/`, prompts for your USB device IDs and peripheral MAC addresses, sets up a launchd agent, and starts the daemon.

To find USB device IDs:
```bash
ioreg -p IOUSB -l | grep -A5 'idVendor\|idProduct'
```

To find peripheral MAC addresses:
```bash
system_profiler SPBluetoothDataType
```

If `~/.local/bin/` isn't in your PATH, add it to your shell config:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

After installing, you should be prompted to approve Bluetooth permissions. You can also grant the permissions in System Settings: **System Settings > Privacy & Security > Bluetooth**.

## Usage

```bash
dockswitch start       # start the daemon
dockswitch stop        # stop the daemon
dockswitch restart     # restart the daemon
dockswitch status      # show running/stopped, PID, versions, config
dockswitch logs        # tail the log file
dockswitch update      # download latest release, replace binaries, restart
dockswitch uninstall   # stop daemon, remove all files
```

## How it works

**On USB device disconnect** (this Mac is losing the peripherals):
- Removes pairing records for each peripheral via `IOBluetoothDevice.remove()`

**On USB device connect** (this Mac is gaining the peripherals):
- Pairs via `IOBluetoothDevicePair.start()`
- Connects with retries via `IOBluetoothDevice.openConnection()`

USB monitoring uses IOKit notifications matching the configured vendor/product ID. Bluetooth operations use the IOBluetooth framework directly with no external dependencies.

## Configuration

Stored in `~/Library/Preferences/com.dockswitch.plist` (created by the installer):

| Key | Description |
|---|---|
| `usbVendorID` | USB vendor ID of the trigger device |
| `usbProductID` | USB product ID of the trigger device |
| `peripheralMACs` | Array of Bluetooth MAC addresses to switch |

## Architecture

Two binaries, one repo:

- **`dockswitchd`** -- Swift daemon (`Sources/DockSwitchD/`), runs as a launchd agent, handles USB monitoring and Bluetooth switching
- **`dockswitch`** -- Rust CLI (`cli/`), manages daemon lifecycle via `launchctl`

## Development

Prerequisites: Xcode (Swift 6.2+), Rust toolchain, a prior `install.sh` run for config/launchd setup.

```bash
./dev-install.sh    # build both binaries, install, and restart daemon
```

Logs are written to `~/Library/Logs/dockswitch.log`.

## License

MIT
