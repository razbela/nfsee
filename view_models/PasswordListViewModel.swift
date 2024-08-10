import SwiftUI
import CryptoKit

class PasswordListViewModel: ObservableObject, PasswordListDelegate {
    @Published var passwords = [PasswordItem]()
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var passwordVisibility = [UUID: Bool]()
    private var nfcService = NFCService()
    private var encryptionService = EncryptionService()

    func loadPasswords() {
        NetworkService.shared.fetchPasswords { [weak self] passwords, errorMessage in
            DispatchQueue.main.async {
                if let passwords = passwords {
                    self?.passwords = passwords
                    self?.passwordVisibility = passwords.reduce(into: [UUID: Bool]()) { result, password in
                        result[password.id] = false
                    }
                    self?.showAlert = false
                } else if let errorMessage = errorMessage {
                    self?.alertMessage = "Failed to load passwords: \(errorMessage)"
                    self?.showAlert = true
                }
            }
        }
    }

    func addPassword(_ password: PasswordItem) {
        startNFCSession(writing: false) { [weak self] keyData, _ in
            guard let self = self, let keyData = keyData else {
                DispatchQueue.main.async {
                    self?.alertMessage = "Failed to read key from NFC."
                    self?.showAlert = true
                }
                return
            }
            let key = SymmetricKey(data: keyData)
            if let encryptedData = self.encryptionService.encrypt(data: Data(password.password.utf8), key: key) {
                var encryptedPassword = password
                encryptedPassword.password = encryptedData.base64EncodedString()
                encryptedPassword.isDecrypted = false
                DispatchQueue.main.async {
                    self.passwords.append(encryptedPassword)
                    self.passwordVisibility[encryptedPassword.id] = false
                    print("Password added locally with ID: \(encryptedPassword.id)")
                }
                NetworkService.shared.addPassword(encryptedPassword) { success, errorMessage in
                    if !success {
                        DispatchQueue.main.async {
                            self.alertMessage = "Failed to add password to server."
                            self.showAlert = true
                        }
                    } else {
                        print("Password added to server with ID: \(encryptedPassword.id)")
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

    func deletePassword(_ passwordId: String) {
        NetworkService.shared.deletePassword(passwordId) { [weak self] success, errorMessage in
            DispatchQueue.main.async {
                if success {
                    if let index = self?.passwords.firstIndex(where: { $0.id.uuidString == passwordId }) {
                        self?.passwords.remove(at: index)
                        self?.passwordVisibility.removeValue(forKey: UUID(uuidString: passwordId)!)
                    }
                    self?.showAlert = false
                } else if let errorMessage = errorMessage {
                    self?.alertMessage = "Failed to delete password: \(errorMessage)"
                    self?.showAlert = true
                }
            }
        }
    }

    func deletePasswords(at offsets: IndexSet) {
        for index in offsets {
            let password = passwords[index]
            deletePassword(password.id.uuidString)
        }
    }

    func movePasswords(from source: IndexSet, to destination: Int) {
        passwords.move(fromOffsets: source, toOffset: destination)
    }

    func toggleEncryption(for password: PasswordItem, completion: @escaping (Bool) -> Void) {
        if password.isDecrypted {
            // Lock the password (Fetch the encrypted password from the local vault)
            print("Fetching password with ID (to lock): \(password.id)") // Add this line
            NetworkService.shared.fetchPassword(by: password.id) { [weak self] encryptedPassword, errorMessage in
                DispatchQueue.main.async {
                    if let encryptedPassword = encryptedPassword {
                        if let index = self?.passwords.firstIndex(where: { $0.id == password.id }) {
                            self?.passwords[index].password = encryptedPassword
                            self?.passwords[index].isDecrypted = false
                            self?.passwordVisibility[password.id] = false
                        }
                        completion(true)
                    } else {
                        self?.alertMessage = "Failed to lock password: \(errorMessage ?? "Unknown error")"
                        self?.showAlert = true
                        completion(false)
                    }
                }
            }
        } else {
            // Unlock the password (Decrypt it using the NFC session)
            startNFCSession(writing: false) { [weak self] keyData, _ in
                guard let self = self, let keyData = keyData else {
                    DispatchQueue.main.async {
                        self?.alertMessage = "Failed to read key from NFC."
                        self?.showAlert = true
                        completion(false)
                    }
                    return
                }
                print("Decrypting password with ID: \(password.id)") // Add this line
                let key = SymmetricKey(data: keyData)
                if let decryptedData = self.encryptionService.decrypt(data: Data(base64Encoded: password.password) ?? Data(), key: key) {
                    if let decryptedPassword = String(data: decryptedData, encoding: .utf8) {
                        if let index = self.passwords.firstIndex(where: { $0.id == password.id }) {
                            self.passwords[index].password = decryptedPassword
                            self.passwords[index].isDecrypted = true
                            self.passwordVisibility[password.id] = false // Set visibility to false when decrypted
                        }
                        completion(true)
                    } else {
                        DispatchQueue.main.async {
                            self.alertMessage = "Failed to decode decrypted password."
                            self.showAlert = true
                            completion(false)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertMessage = "Failed to decrypt password."
                        self.showAlert = true
                        completion(false)
                    }
                }
            }
        }
    }


    private func startNFCSession(writing: Bool, completion: @escaping (Data?, String?) -> Void) {
        print("Starting NFC session - Writing: \(writing)")
        nfcService.startSession(prompt: true, writing: writing, completion: completion)
    }
}
