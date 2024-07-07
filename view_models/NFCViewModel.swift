import Foundation
import SwiftUI
import Combine
import CryptoKit

class NFCViewModel: ObservableObject {
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var navigateToPasswordList = false
    
    private var nfcService = NFCService()
    
    init() {}
    
    func startNFCSession(writing: Bool, completion: @escaping (Data?) -> Void) {
        nfcService.startSession(prompt: true, writing: writing) { [weak self] keyData in
            DispatchQueue.main.async {
                completion(keyData)
            }
        }
    }
    
    func writeKeyToNFC() {
        startNFCSession(writing: true) { [weak self] keyData in
            guard let self = self else { return }
            if let keyData = keyData {
                UserDefaults.standard.set(true, forKey: "keyWritten")
                self.alertMessage = "Key successfully written to NFC."
                self.navigateToPasswordList = true
                print("Key written to NFC: \(keyData.base64EncodedString())")
            } else {
                self.alertMessage = "Failed to write key to NFC."
                self.showAlert = true
            }
        }
    }
}
