# DockSwitch

A lightweight macOS daemon that automatically switches Apple Magic Keyboard and Magic Trackpad between two Macs when an Apple Studio Display is connected or disconnected.

## Why

Apple Magic peripherals don't support multi-device pairing. They bind to a single host via USB and won't advertise to other devices after a software disconnect. DockSwitch solves this by removing the pairing record when the display disconnects, forcing the peripheral into an advertising/pairable state so the other Mac can pick it up.

No power cycling, no manual re-pairing, no network coordination between machines. Each Mac runs the daemon independently and reacts to its own dock events.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ljredmond9/DockSwitch/main/install.sh | bash
```

The installer downloads both binaries to `~/.local/bin/`, prompts for your peripheral MAC addresses, sets up a launchd agent, and starts the daemon.

After installing, grant Bluetooth permission to the daemon: **System Settings > Privacy & Security > Bluetooth**.

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

**On dock disconnect** (this Mac is losing the peripherals):
- Removes pairing records for each peripheral via `IOBluetoothDevice.remove()`

**On dock connect** (this Mac is gaining the peripherals):
- Pairs via `IOBluetoothDevicePair.start()`
- Connects with retries via `IOBluetoothDevice.openConnection()`

USB monitoring uses IOKit notifications matching the Studio Display's vendor/product ID. Bluetooth operations use the IOBluetooth framework directly with no external dependencies.

## Configuration

Stored in `~/Library/Preferences/com.dockswitch.plist` (created by the installer):

| Key | Description | Default |
|---|---|---|
| `dockVendorID` | USB vendor ID of the dock/display | `1452` (Apple) |
| `dockProductID` | USB product ID of the dock/display | `4372` (Studio Display) |
| `peripheralMACs` | Array of Bluetooth MAC addresses to switch | _(set during install)_ |

To find your peripheral MAC addresses:
```bash
system_profiler SPBluetoothDataType
```

## Architecture

Two binaries, one repo:

- **`dockswitchd`** -- Swift daemon (`Sources/DockSwitchD/`), runs as a launchd agent, handles USB monitoring and Bluetooth switching
- **`dockswitch`** -- Rust CLI (`cli/`), manages daemon lifecycle via `launchctl`

## Development

Prerequisites: Xcode (Swift 6.2+), Rust toolchain, a prior `install.sh` run for config/launchd setup.

```bash
./dev-install.sh    # build both binaries, install, and restart daemon
```

Logs are written to `~/Library/Logs/DockSwitch.log`.

## License

MIT
