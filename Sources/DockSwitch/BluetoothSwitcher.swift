import Foundation
import IOBluetooth

struct BluetoothSwitcher {
    let peripheralMACs: [String]
    let maxRetries: Int
    let retryDelay: TimeInterval

    init(
        peripheralMACs: [String],
        maxRetries: Int = 5,
        retryDelay: TimeInterval = 2.0
    ) {
        self.peripheralMACs = peripheralMACs
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }

    /// Display connected — this Mac is gaining the peripherals.
    /// Skip devices already connected; unpair (clear stale record), pair, then connect with retries for the rest.
    func pairAndConnect() {
        for mac in peripheralMACs {
            if isConnected(mac) {
                log("\(mac) already connected — skipping")
                continue
            }

            log("Pairing \(mac)...")
            remove(mac)
            Thread.sleep(forTimeInterval: 1.0)
            pair(mac)
            Thread.sleep(forTimeInterval: 1.0)

            var connected = false
            for attempt in 1...maxRetries {
                if connect(mac) {
                    log("Connected \(mac) on attempt \(attempt)")
                    connected = true
                    break
                }
                log("Connect attempt \(attempt)/\(maxRetries) failed for \(mac), retrying in \(retryDelay)s...")
                Thread.sleep(forTimeInterval: retryDelay)
            }
            if !connected {
                log("ERROR: Failed to connect \(mac) after \(maxRetries) attempts")
            }
        }
    }

    /// Display disconnected — this Mac is losing the peripherals.
    /// Unpair so peripherals enter advertising mode for the other Mac.
    func unpair() {
        for mac in peripheralMACs {
            log("Unpairing \(mac)...")
            remove(mac)
        }
    }

    // MARK: - IOBluetooth operations

    private func device(for mac: String) -> IOBluetoothDevice? {
        guard let device = IOBluetoothDevice(addressString: mac) else {
            log("ERROR: Could not create IOBluetoothDevice for \(mac)")
            return nil
        }
        return device
    }

    private func isConnected(_ mac: String) -> Bool {
        guard let device = device(for: mac) else { return false }
        let connected = device.isConnected()
        log("isConnected(\(mac)): \(connected)")
        return connected
    }

    /// Remove pairing record (private API — same call blueutil uses internally).
    /// Forces the peripheral into advertising/pairable mode.
    @discardableResult
    private func remove(_ mac: String) -> Bool {
        guard let device = device(for: mac) else { return false }
        let selector = Selector(("remove"))
        guard device.responds(to: selector) else {
            log("ERROR: IOBluetoothDevice does not respond to 'remove' — macOS version may be unsupported")
            return false
        }
        device.perform(selector)
        log("Removed pairing for \(mac)")
        return true
    }

    private func pair(_ mac: String) {
        guard let device = device(for: mac) else { return }
        let pairDelegate = PairDelegate(mac: mac)
        guard let pair = IOBluetoothDevicePair(device: device) else {
            log("ERROR: Could not create IOBluetoothDevicePair for \(mac)")
            return
        }
        pair.delegate = pairDelegate

        let result = pair.start()
        if result != kIOReturnSuccess {
            log("ERROR: Pair start failed for \(mac): \(result)")
            return
        }

        // Wait for pairing to complete (delegate sets the semaphore)
        pairDelegate.wait()
    }

    @discardableResult
    private func connect(_ mac: String) -> Bool {
        guard let device = device(for: mac) else { return false }
        let result = device.openConnection()
        let success = result == kIOReturnSuccess
        log("openConnection(\(mac)): \(success ? "success" : "failed (\(result))")")
        return success
    }
}

/// Delegate to handle IOBluetoothDevicePair callbacks synchronously.
private final class PairDelegate: NSObject, IOBluetoothDevicePairDelegate {
    let mac: String
    private let semaphore = DispatchSemaphore(value: 0)

    init(mac: String) {
        self.mac = mac
    }

    func wait() {
        _ = semaphore.wait(timeout: .now() + 15)
    }

    func devicePairingFinished(_ sender: Any?, error: IOReturn) {
        if error == kIOReturnSuccess {
            log("Pairing completed for \(mac)")
        } else {
            log("ERROR: Pairing failed for \(mac): \(error)")
        }
        semaphore.signal()
    }

    func devicePairingPINCodeRequest(_ sender: Any?) {
        log("PIN requested for \(mac) — providing 0000")
        guard let pair = sender as? IOBluetoothDevicePair else { return }
        var pin = BluetoothPINCode()
        let pinBytes: [UInt8] = [0x30, 0x30, 0x30, 0x30] // "0000" in ASCII
        withUnsafeMutableBytes(of: &pin.data) { buffer in
            for (i, byte) in pinBytes.enumerated() {
                buffer[i] = byte
            }
        }
        pair.replyPINCode(4, pinCode: &pin)
    }
}
