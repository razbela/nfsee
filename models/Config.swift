import Foundation

class Config {
    static let shared = Config()
    
    private let ipAddressKey = "ServerIPAddress"
    private let portKey = "ServerPort"
    private let configFileName = "config"
    private let configFileExtension = "json"
    
    private init() {
        loadConfigFromFile()
    }
    
    private func loadConfigFromFile() {
        guard let url = Bundle.main.url(forResource: configFileName, withExtension: configFileExtension) else {
            print("Config file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                if let ipAddress = json[ipAddressKey] {
                    UserDefaults.standard.set(ipAddress, forKey: ipAddressKey)
                }
                if let port = json[portKey] {
                    UserDefaults.standard.set(port, forKey: portKey)
                }
            }
        } catch {
            print("Error reading config file: \(error)")
        }
    }
    
    var serverIPAddress: String {
        get {
            return UserDefaults.standard.string(forKey: ipAddressKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ipAddressKey)
        }
    }

    var serverPort: String {
        get {
            return UserDefaults.standard.string(forKey: portKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: portKey)
        }
    }
}
