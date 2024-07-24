import Foundation

class Config {
    static let shared = Config()
    
    private let ipAddressKey = "ServerIPAddress"
    private let portKey = "ServerPort"
    
    private init() {
        if UserDefaults.standard.string(forKey: ipAddressKey) == nil {
            // Set a default IP address if not already set
            UserDefaults.standard.set("10.100.102.16", forKey: ipAddressKey)
        }
        if UserDefaults.standard.string(forKey: portKey) == nil {
            // Set a default port if not already set
            UserDefaults.standard.set("4444", forKey: portKey)
        }
    }
    
    var serverIPAddress: String {
        get {
            return UserDefaults.standard.string(forKey: ipAddressKey) ?? "10.100.102.16"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ipAddressKey)
        }
    }

    var serverPort: String {
        get {
            return UserDefaults.standard.string(forKey: portKey) ?? "4444"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: portKey)
        }
    }
}
