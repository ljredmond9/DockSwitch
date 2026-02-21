import Foundation

struct Config {
    let usbVendorID: Int
    let usbProductID: Int
    let peripheralMACs: [String]

    static let plistPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Preferences/com.dockswitch.plist"
    }()

    static func load() -> Config {
        guard FileManager.default.fileExists(atPath: plistPath) else {
            fatalError("Config file not found at \(plistPath). Run install.sh to configure DockSwitch.")
        }

        guard let dict = NSDictionary(contentsOfFile: plistPath) as? [String: Any] else {
            fatalError("Failed to read config plist at \(plistPath).")
        }

        guard let vendorID = dict["usbVendorID"] as? Int else {
            fatalError("Missing 'usbVendorID' in config plist.")
        }
        guard let productID = dict["usbProductID"] as? Int else {
            fatalError("Missing 'usbProductID' in config plist.")
        }
        guard let macs = dict["peripheralMACs"] as? [String], !macs.isEmpty else {
            fatalError("Missing or empty 'peripheralMACs' in config plist.")
        }

        return Config(
            usbVendorID: vendorID,
            usbProductID: productID,
            peripheralMACs: macs
        )
    }
}
