import SwiftUI
import CryptoKit

class PasswordListViewModel: ObservableObject, PasswordListDelegate {
    @Published var passwords = [PasswordItem]()
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var passwordVisibility = [UUID: Bool]()
    private var nfcService = NFCService()
    private var encryptionService = EncryptionService()
    @Published var remainingTime = [UUID: Int]()
    private var timers = [UUID: Timer]()


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
    func setupTimers() {
           passwords.forEach { password in
               if password.isDecrypted {
                   startTimer(for: password.id)
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
            print("Fetching password with ID (to lock): \(password.id)")
            NetworkService.shared.fetchPassword(by: password.id) { [weak self] encryptedPassword, errorMessage in
                DispatchQueue.main.async {
                    guard let self = self, let encryptedPassword = encryptedPassword else {
                        self?.alertMessage = "Failed to lock password: \(errorMessage ?? "Unknown error")"
                        self?.showAlert = true
                        completion(false)
                        return
                    }
                    if let index = self.passwords.firstIndex(where: { $0.id == password.id }) {
                        self.passwords[index].password = encryptedPassword
                        self.passwords[index].isDecrypted = false
                        self.passwordVisibility[password.id] = false
                        self.clearTimer(for: password.id)
                    }
                    completion(true)
                }
            }
        } else {
            // Decrypt the password (Unlock it using the NFC session)
            startNFCSession(writing: false) { [weak self] keyData, _ in
                guard let self = self, let keyData = keyData else {
                    DispatchQueue.main.async {
                        self?.alertMessage = "Failed to read key from NFC."
                        self?.showAlert = true
                        completion(false)
                    }
                    return
                }
                print("Decrypting password with ID: \(password.id)")
                let key = SymmetricKey(data: keyData)
                if let decryptedData = self.encryptionService.decrypt(data: Data(base64Encoded: password.password) ?? Data(), key: key),
                   let decryptedPassword = String(data: decryptedData, encoding: .utf8) {
                    DispatchQueue.main.async {
                        if let index = self.passwords.firstIndex(where: { $0.id == password.id }) {
                            self.passwords[index].password = decryptedPassword
                            self.passwords[index].isDecrypted = true
                            self.startTimer(for: password.id)
                        }
                        completion(true)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertMessage = "Failed to decode decrypted password."
                        self.showAlert = true
                        completion(false)
                    }
                }
            }
        }
    }

    private func startTimer(for passwordId: UUID) {
        clearTimer(for: passwordId)
        remainingTime[passwordId] = 15  // Start with 15 seconds
        timers[passwordId] = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let timeLeft = self.remainingTime[passwordId], timeLeft > 0 {
                    self.remainingTime[passwordId] = timeLeft - 1
                } else {
                    timer.invalidate()
                    self.remainingTime[passwordId] = nil
                    // Directly use toggleEncryption to lock the password
                    if let password = self.passwords.first(where: { $0.id == passwordId }) {
                        if password.isDecrypted {  // Double check to ensure it's still decrypted before locking
                            self.toggleEncryption(for: password) { success in
                                // Handle post-lock actions here, if necessary
                            }
                        }
                    }
                }
            }
        }
    }

    private func clearTimer(for passwordId: UUID) {
        timers[passwordId]?.invalidate()
        timers.removeValue(forKey: passwordId)
    }


    private func startNFCSession(writing: Bool, completion: @escaping (Data?, String?) -> Void) {
        print("Starting NFC session - Writing: \(writing)")
        nfcService.startSession(prompt: true, writing: writing, completion: completion)
    }
}
