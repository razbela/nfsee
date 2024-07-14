import Foundation
import SwiftUI
import Combine
import CryptoKit

class NFCViewModel: ObservableObject {
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var navigateToPasswordList = false
    @Published var nfcUid: String?

    private var nfcService = NFCService()
    
    init() {}
    
    func startNFCSession(writing: Bool, completion: @escaping (Data?, String?) -> Void) {
        nfcService.startSession(prompt: true, writing: writing) { [weak self] keyData, uid in
            DispatchQueue.main.async {
                self?.nfcUid = uid  // Set the UID
                completion(keyData, uid)
            }
        }
    }
    
    func writeKeyToNFC() {
        startNFCSession(writing: true) { [weak self] keyData, uid in
            guard let self = self else { return }
            if let keyData = keyData, let uid = uid {
                UserDefaults.standard.set(true, forKey: "keyWritten")
                self.alertMessage = "Key successfully written to NFC."
                self.navigateToPasswordList = true
                self.nfcUid = uid
                print("Key written to NFC: \(keyData.base64EncodedString())")
                print("NFC UID: \(uid)")
            } else {
                self.alertMessage = "Failed to write key to NFC."
                self.showAlert = true
            }
        }
    }
}
