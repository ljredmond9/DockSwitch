import Foundation
import IOKit
import IOKit.usb

final class USBMonitor: @unchecked Sendable {
    private let vendorID: Int
    private let productID: Int
    private let notifyPort: IONotificationPortRef
    private var matchIterator: io_iterator_t = 0
    private var removeIterator: io_iterator_t = 0

    var onDockConnected: (() -> Void)?
    var onDockDisconnected: (() -> Void)?

    init(vendorID: Int, productID: Int) {
        self.vendorID = vendorID
        self.productID = productID
        self.notifyPort = IONotificationPortCreate(kIOMainPortDefault)
    }

    deinit {
        IOObjectRelease(matchIterator)
        IOObjectRelease(removeIterator)
        IONotificationPortDestroy(notifyPort)
    }

    func start() {
        let runLoopSource = IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)

        let matchingDict = IOServiceMatching("IOUSBHostDevice") as NSMutableDictionary
        matchingDict["idVendor"] = vendorID
        matchingDict["idProduct"] = productID

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        // Watch for device attach
        let matchDict1 = matchingDict.mutableCopy() as! NSMutableDictionary
        IOServiceAddMatchingNotification(
            notifyPort,
            kIOMatchedNotification,
            matchDict1,
            deviceAttached,
            selfPtr,
            &matchIterator
        )
        // Drain existing matches
        drainIterator(matchIterator)

        // Watch for device detach
        let matchDict2 = matchingDict.mutableCopy() as! NSMutableDictionary
        IOServiceAddMatchingNotification(
            notifyPort,
            kIOTerminatedNotification,
            matchDict2,
            deviceRemoved,
            selfPtr,
            &removeIterator
        )
        // Drain existing matches
        drainIterator(removeIterator)

        log("USB monitor started — watching for vendor=0x\(String(vendorID, radix: 16)) product=0x\(String(productID, radix: 16))")
    }

    /// Check if the dock is currently connected.
    func isDockConnected() -> Bool {
        let matchingDict = IOServiceMatching("IOUSBHostDevice") as NSMutableDictionary
        matchingDict["idVendor"] = vendorID
        matchingDict["idProduct"] = productID

        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        guard kr == KERN_SUCCESS else { return false }

        let service = IOIteratorNext(iterator)
        IOObjectRelease(iterator)
        if service != 0 {
            IOObjectRelease(service)
            return true
        }
        return false
    }

    private func drainIterator(_ iterator: io_iterator_t) {
        while case let service = IOIteratorNext(iterator), service != 0 {
            IOObjectRelease(service)
        }
    }
}

// MARK: - IOKit C callbacks

private func deviceAttached(refcon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    guard let refcon else { return }
    let monitor = Unmanaged<USBMonitor>.fromOpaque(refcon).takeUnretainedValue()

    // Drain the iterator (required to re-arm the notification)
    while case let service = IOIteratorNext(iterator), service != 0 {
        IOObjectRelease(service)
    }

    log("Dock connected")
    monitor.onDockConnected?()
}

private func deviceRemoved(refcon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    guard let refcon else { return }
    let monitor = Unmanaged<USBMonitor>.fromOpaque(refcon).takeUnretainedValue()

    while case let service = IOIteratorNext(iterator), service != 0 {
        IOObjectRelease(service)
    }

    log("Dock disconnected")
    monitor.onDockDisconnected?()
}
