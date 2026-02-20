import Foundation

struct BluetoothSwitcher {
    let bleutilPath: String
    let peripheralMACs: [String]
    let maxRetries: Int
    let retryDelay: TimeInterval

    init(
        bleutilPath: String = "/opt/homebrew/bin/blueutil",
        peripheralMACs: [String],
        maxRetries: Int = 5,
        retryDelay: TimeInterval = 2.0
    ) {
        self.bleutilPath = bleutilPath
        self.peripheralMACs = peripheralMACs
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }

    /// Display connected — this Mac is gaining the peripherals.
    /// Unpair (clear stale record), pair, then connect with retries.
    func pairAndConnect() {
        for mac in peripheralMACs {
            log("Pairing \(mac)...")
            blueutil("--unpair", mac)
            blueutil("--pair", mac)

            var connected = false
            for attempt in 1...maxRetries {
                let result = blueutil("--connect", mac)
                if result == 0 {
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
            blueutil("--unpair", mac)
        }
    }

    @discardableResult
    private func blueutil(_ args: String...) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: bleutilPath)
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            log("ERROR: Failed to run blueutil: \(error)")
            return -1
        }

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !output.isEmpty {
            log("blueutil \(args.joined(separator: " ")): \(output)")
        }

        return process.terminationStatus
    }
}
