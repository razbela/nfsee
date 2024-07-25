import SwiftUI
import CryptoKit

class PasswordListViewModel: ObservableObject, PasswordListDelegate {
    @Published var passwords = [PasswordItem]()
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isListening = false
    private var nfcService = NFCService()
    private var encryptionService = EncryptionService()
    
    func loadPasswords() {
           guard let token = UserDefaults.standard.string(forKey: "jwtToken") else {
               alertMessage = "User is not authenticated."
               showAlert = true
               return
           }
        
        NetworkService.shared.fetchPasswords { passwords, errorMessage in
                   DispatchQueue.main.async {
                       if let passwords = passwords {
                           self.passwords = passwords
                           self.showAlert = false  // Ensure alert is not shown on success
                       } else if let errorMessage = errorMessage {
                           self.alertMessage = "Failed to load passwords: \(errorMessage)"
                           self.showAlert = true
                       }
                   }
               }
           }
    
    func addPassword(_ password: PasswordItem) {
            print("Adding password: \(password.title)")
            startNFCSession(writing: false) { [weak self] keyData, _ in
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
                    encryptedPassword.isDecrypted = false
                    print("Original password: \(password.password)")
                    print("Encrypted password: \(encryptedPassword.password)")
                    DispatchQueue.main.async {
                        self.passwords.append(encryptedPassword)
                        print("Passwords count: \(self.passwords.count)")
                    }
                    NetworkService.shared.addPassword(encryptedPassword) { success, errorMessage in
                        if !success {
                            DispatchQueue.main.async {
                                self.alertMessage = "Failed to add password to server."
                                self.showAlert = true
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertMessage = "Failed to encrypt password."
                        self.showAlert = true
                    }
                }
            }
        }
    func deletePassword(_ password: PasswordItem) {
            NetworkService.shared.deletePassword(password) { success, errorMessage in
                DispatchQueue.main.async {
                    if success {
                        if let index = self.passwords.firstIndex(where: { $0.id == password.id }) {
                            self.passwords.remove(at: index)
                        }
                        self.showAlert = false
                    } else if let errorMessage = errorMessage {
                        self.alertMessage = "Failed to delete password: \(errorMessage)"
                        self.showAlert = true
                    }
                }
            }
        }
    func deletePasswords(at offsets: IndexSet) {
           offsets.map { self.passwords[$0] }.forEach { password in
               self.deletePassword(password)
           }
       }

    func movePasswords(from source: IndexSet, to destination: Int) {
        passwords.move(fromOffsets: source, toOffset: destination)
    }
    
    func toggleEncryption(for password: PasswordItem, completion: @escaping (Bool) -> Void) {
        startNFCSession(writing: false) { [weak self] keyData, _ in
            guard let self = self, let keyData = keyData else {
                DispatchQueue.main.async {
                    self?.alertMessage = "Failed to read key from NFC."
                    self?.showAlert = true
                    completion(false)
                }
                return
            }
            let key = SymmetricKey(data: keyData)
            if password.isDecrypted {
                if let decryptedData = password.password.data(using: .utf8),
                   let encryptedData = self.encryptionService.encrypt(data: decryptedData, key: key) {
                    DispatchQueue.main.async {
                        if let index = self.passwords.firstIndex(of: password) {
                            self.passwords[index].password = encryptedData.base64EncodedString()
                            self.passwords[index].isDecrypted = false
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                } else {
                    completion(false)
                }
            } else {
                if let encryptedData = Data(base64Encoded: password.password),
                   let decryptedData = self.encryptionService.decrypt(data: encryptedData, key: key) {
                    DispatchQueue.main.async {
                        if let index = self.passwords.firstIndex(of: password) {
                            self.passwords[index].password = String(data: decryptedData, encoding: .utf8) ?? "Decryption failed"
                            self.passwords[index].isDecrypted = true
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    private func startNFCSession(writing: Bool, completion: @escaping (Data?, String?) -> Void) {
        print("Starting NFC session - Writing: \(writing)")
        nfcService.startSession(prompt: true, writing: writing, completion: completion)
    }
}
