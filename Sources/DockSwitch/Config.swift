import Foundation

struct Config {
    let dockVendorID: Int
    let dockProductID: Int
    let peripheralMACs: [String]
    let bleutilPath: String

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

        guard let vendorID = dict["dockVendorID"] as? Int else {
            fatalError("Missing 'dockVendorID' in config plist.")
        }
        guard let productID = dict["dockProductID"] as? Int else {
            fatalError("Missing 'dockProductID' in config plist.")
        }
        guard let macs = dict["peripheralMACs"] as? [String], !macs.isEmpty else {
            fatalError("Missing or empty 'peripheralMACs' in config plist.")
        }

        let bleutilPath = dict["bleutilPath"] as? String ?? "/opt/homebrew/bin/blueutil"

        return Config(
            dockVendorID: vendorID,
            dockProductID: productID,
            peripheralMACs: macs,
            bleutilPath: bleutilPath
        )
    }
}
