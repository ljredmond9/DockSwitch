import Foundation
import IOBluetooth

@main
struct DockSwitch {
    static func main() {
        if CommandLine.arguments.contains("--version") {
            print("dockswitchd \(version)")
            return
        }

        let config = Config.load()
        log("dockswitchd v\(version) starting (vendor=0x\(String(config.usbVendorID, radix: 16)), product=0x\(String(config.usbProductID, radix: 16)), peripherals=\(config.peripheralMACs))")

        // Trigger Bluetooth permission prompt early (before any dock events)
        _ = IOBluetoothDevice.pairedDevices()

        let switcher = BluetoothSwitcher(peripheralMACs: config.peripheralMACs)
        let monitor = USBMonitor(vendorID: config.usbVendorID, productID: config.usbProductID)

        monitor.onDeviceConnected = {
            log("USB device connected — pairing peripherals")
            DispatchQueue.global(qos: .userInitiated).async {
                switcher.pairAndConnect()
            }
        }

        monitor.onDeviceDisconnected = {
            log("USB device disconnected — unpairing peripherals")
            DispatchQueue.global(qos: .userInitiated).async {
                switcher.unpair()
            }
        }

        // Check initial state
        if monitor.isDeviceConnected() {
            log("USB trigger device is already connected at launch")
        } else {
            log("USB trigger device is not connected at launch")
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
