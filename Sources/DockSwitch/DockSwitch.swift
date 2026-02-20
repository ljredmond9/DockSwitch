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

        log("Entering run loop")
        RunLoop.current.run()
    }
}
