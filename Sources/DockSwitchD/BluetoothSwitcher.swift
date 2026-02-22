import Foundation
import IOBluetooth

struct BluetoothSwitcher {
    let peripheralMACs: [String]
    let maxRetries: Int
    let retryDelay: TimeInterval
    /// Number of times to retry the full pair+connect cycle if the peripheral is
    /// not advertising (e.g. it went back to sleep after a long disconnect gap).
    let maxPairAttempts: Int
    /// How long to wait between full pair+connect cycle retries. Should be long
    /// enough for the user to interact with the peripheral and trigger advertising.
    let pairRetryDelay: TimeInterval

    init(
        peripheralMACs: [String],
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 2.0,
        maxPairAttempts: Int = 10,
        pairRetryDelay: TimeInterval = 30.0
    ) {
        self.peripheralMACs = peripheralMACs
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.maxPairAttempts = maxPairAttempts
        self.pairRetryDelay = pairRetryDelay
    }

    /// USB device connected — this Mac is gaining the peripherals.
    /// Skip devices already connected; pair and then connect with retries for the rest.
    ///
    /// Two retry levels:
    ///   Outer (maxPairAttempts × pairRetryDelay): retries the full pair+connect
    ///     sequence to handle the case where the peripheral has gone back to sleep
    ///     after a long gap since the other Mac removed the pairing record.
    ///   Inner (maxRetries × retryDelay): retries just the connect step to handle
    ///     the case where the peripheral is still entering advertising mode.
    func pairAndConnect() {
        for mac in peripheralMACs {
            if isConnected(mac) {
                log("\(mac) already connected — skipping")
                continue
            }

            var connected = false
            for pairAttempt in 1...maxPairAttempts {
                log("Pair+connect attempt \(pairAttempt)/\(maxPairAttempts) for \(mac)...")

                let paired = pair(mac)
                if !paired {
                    // Pairing timed out — peripheral is not advertising yet.
                    // Wait and retry the full cycle.
                    log("Pairing timed out for \(mac) (attempt \(pairAttempt)/\(maxPairAttempts)); waiting \(pairRetryDelay)s for peripheral to enter advertising mode...")
                    Thread.sleep(forTimeInterval: pairRetryDelay)
                    continue
                }

                for attempt in 1...maxRetries {
                    if connect(mac) {
                        log("Connected \(mac) on connect attempt \(attempt) (pair attempt \(pairAttempt))")
                        connected = true
                        break
                    }
                    log("Connect attempt \(attempt)/\(maxRetries) failed for \(mac), retrying in \(retryDelay)s...")
                    Thread.sleep(forTimeInterval: retryDelay)
                }

                if connected { break }

                log("Connect failed after \(maxRetries) attempts for \(mac) (pair attempt \(pairAttempt)/\(maxPairAttempts)); waiting \(pairRetryDelay)s before retrying pair...")
                Thread.sleep(forTimeInterval: pairRetryDelay)
            }

            if !connected {
                log("ERROR: Failed to connect \(mac) after \(maxPairAttempts) pair attempts")
            }
        }
    }

    /// USB device disconnected — this Mac is losing the peripherals.
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

    @discardableResult
    private func pair(_ mac: String) -> Bool {
        guard let device = device(for: mac) else { return false }
        let pairDelegate = PairDelegate(mac: mac)
        guard let pair = IOBluetoothDevicePair(device: device) else {
            log("ERROR: Could not create IOBluetoothDevicePair for \(mac)")
            return false
        }
        pair.delegate = pairDelegate

        let result = pair.start()
        if result != kIOReturnSuccess {
            log("ERROR: Pair start failed for \(mac): \(result)")
            return false
        }

        // Wait for pairing to complete (delegate sets the semaphore)
        return pairDelegate.wait()
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
    private var succeeded = false

    init(mac: String) {
        self.mac = mac
    }

    /// Returns true if pairing completed successfully, false if it failed or timed out.
    func wait() -> Bool {
        let timedOut = semaphore.wait(timeout: .now() + 15) == .timedOut
        if timedOut {
            log("Pairing timed out for \(mac) — peripheral may not be advertising")
        }
        return !timedOut && succeeded
    }

    func devicePairingFinished(_ sender: Any?, error: IOReturn) {
        if error == kIOReturnSuccess {
            log("Pairing completed for \(mac)")
            succeeded = true
        } else {
            log("ERROR: Pairing failed for \(mac): \(error)")
            succeeded = false
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
