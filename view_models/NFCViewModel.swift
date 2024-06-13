import Foundation
import SwiftUI
import Combine
import CryptoKit

class NFCViewModel: ObservableObject {
    @Published var isKeyWritten = false
    @Published var keyData: String?
    @Published var showAlert = false {
        didSet {
            if showAlert {
                print("Alert is set to show with message: \(alertMessage)")
            } else {
                print("Alert is not showing")
            }
        }
    }
    @Published var alertMessage = ""
    @Published var navigateToPasswordList = false
    
    private var nfcService = NFCService()
    
    func startNFCSession() {
        DispatchQueue.main.async {
            self.nfcService.startSession { [weak self] keyData in
                DispatchQueue.main.async {
                    if let keyData = keyData {
                        print("NFC Key Data: \(keyData.base64EncodedString())")
                        self?.keyData = keyData.base64EncodedString()
                        self?.alertMessage = "Key written successfully: \(self?.keyData ?? "")"
                        self?.isKeyWritten = true
                        self?.navigateToPasswordList = true
                        self?.showAlert = false  // Explicitly set to false on success
                    } else {
                        print("NFC Key Data is nil")
                        self?.alertMessage = "Failed to write key to NFC."
                        self?.showAlert = true
                    }
                }
            }
        }
    }
}
