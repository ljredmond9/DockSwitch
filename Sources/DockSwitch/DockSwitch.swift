import Foundation

@main
struct DockSwitch {
    static func main() {
        if CommandLine.arguments.contains("--version") {
            print("DockSwitch \(version)")
            return
        }

        let config = Config.load()
        log("DockSwitch v\(version) starting (vendor=0x\(String(config.dockVendorID, radix: 16)), product=0x\(String(config.dockProductID, radix: 16)), peripherals=\(config.peripheralMACs))")

        // Trigger Bluetooth TCC prompt on first launch by running a harmless blueutil command
        let preflight = Process()
        preflight.executableURL = URL(fileURLWithPath: config.bleutilPath)
        preflight.arguments = ["--power"]
        preflight.standardOutput = FileHandle.nullDevice
        preflight.standardError = FileHandle.nullDevice
        try? preflight.run()
        preflight.waitUntilExit()

        let switcher = BluetoothSwitcher(bleutilPath: config.bleutilPath, peripheralMACs: config.peripheralMACs)
        let monitor = USBMonitor(vendorID: config.dockVendorID, productID: config.dockProductID)

        monitor.onDockConnected = {
            log("Display connected — pairing peripherals")
            DispatchQueue.global(qos: .userInitiated).async {
                switcher.pairAndConnect()
            }
        }

        monitor.onDockDisconnected = {
            log("Display disconnected — unpairing peripherals")
            DispatchQueue.global(qos: .userInitiated).async {
                switcher.unpair()
            }
        }

        // Check initial state
        if monitor.isDockConnected() {
            log("Display is already connected at launch")
        } else {
            log("Display is not connected at launch")
        }

        monitor.start()

        let shutdownHandler: @convention(c) (Int32) -> Void = { signal in
            log("Shutting down (signal \(signal))")
            exit(0)
        }
        signal(SIGTERM, shutdownHandler)
        signal(SIGINT, shutdownHandler)

        log("Entering run loop")
        RunLoop.current.run()
    }
}
