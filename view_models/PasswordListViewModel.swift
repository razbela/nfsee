import Foundation
import SwiftUI
import CryptoKit

class PasswordListViewModel: ObservableObject, PasswordListDelegate {
    @Published var passwords = [PasswordItem]()
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isListening = false
    private var nfcService = NFCService()
    private var encryptionService = EncryptionService()
    
    func addPassword(_ password: PasswordItem) {
        print("Adding password: \(password.title)")
        startNFCSession(writing: false) { [weak self] keyData in
            guard let self = self, let keyData = keyData else {
                DispatchQueue.main.async {
                    self?.alertMessage = "Failed to read key from NFC."
                    self?.showAlert = true
                }
                return
            }
            print("Key read from NFC: \(keyData.base64EncodedString())")
            let key = SymmetricKey(data: keyData)
            if let encryptedData = self.encryptionService.encrypt(data: Data(password.password.utf8), key: key) {
                var encryptedPassword = password
                encryptedPassword.password = encryptedData.base64EncodedString()
                print("Original password: \(password.password)")
                print("Encrypted password: \(encryptedPassword.password)")
                DispatchQueue.main.async {
                    self.passwords.append(encryptedPassword)
                    print("Passwords count: \(self.passwords.count)")
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = "Failed to encrypt password."
                    self.showAlert = true
                }
            }
        }
    }

    func deletePasswords(at offsets: IndexSet) {
        DispatchQueue.main.async {
            self.passwords.remove(atOffsets: offsets)
        }
    }

    func movePasswords(from source: IndexSet, to destination: Int) {
        DispatchQueue.main.async {
            self.passwords.move(fromOffsets: source, toOffset: destination)
        }
    }

    func toggleNFCListening() {
        if isListening {
            nfcService.stopSession()
            DispatchQueue.main.async {
                self.isListening.toggle()
            }
        } else {
            startNFCSession(writing: false) { [weak self] keyData in
                guard let self = self, let keyData = keyData else {
                    DispatchQueue.main.async {
                        self?.alertMessage = "Failed to read key from NFC."
                        self?.showAlert = true
                    }
                    return
                }
                print("Key read from NFC for decryption: \(keyData.base64EncodedString())")
                self.decryptPasswords(with: keyData)
                DispatchQueue.main.async {
                    self.isListening.toggle()
                }
            }
        }
    }

    private func startNFCSession(writing: Bool, completion: @escaping (Data?) -> Void) {
        print("Starting NFC session - Writing: \(writing)")
        nfcService.startSession(prompt: true, writing: writing, completion: completion)
    }

    private func decryptPasswords(with keyData: Data) {
        let key = SymmetricKey(data: keyData)
        for (index, password) in passwords.enumerated() {
            if let encryptedData = Data(base64Encoded: password.password),
               let decryptedData = encryptionService.decrypt(data: encryptedData, key: key) {
                DispatchQueue.main.async {
                    self.passwords[index].password = String(data: decryptedData, encoding: .utf8) ?? "Decryption failed"
                    self.passwords[index].isDecrypted = true
                }
            }
        }
    }
}
