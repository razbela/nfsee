import SwiftUI
import UIKit
import CoreNFC
import CryptoKit
import LocalAuthentication

struct SettingsView: View {
    @State private var serverIPAddress: String = Config.shared.serverIPAddress
    @State private var serverPort: String = Config.shared.serverPort
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var passwordListViewModel: PasswordListViewModel
    @EnvironmentObject var nfcViewModel: NFCViewModel
    @State private var showingDocumentPicker = false
    @State private var storedNFCKey: String?
    @State private var showingSecretKeyAlert = false

    var body: some View {
            ZStack {
                AppColors.black.edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.white)
                        .padding(.top, 20)
                    
                    Button(action: authenticateAndCopyNFCKey) {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                            Text("Copy NFC Key")
                        }
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.white)
                        .foregroundColor(AppColors.black)
                        .cornerRadius(9)
                    }
                    .padding(.top, 10)
                    
                    Button(action: exportPasswords) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Passwords")
                        }
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.white)
                        .foregroundColor(AppColors.black)
                        .cornerRadius(9)
                    }
                    .padding(.top, 10)
                    
                    Button(action: importPasswords) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Passwords")
                        }
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.white)
                        .foregroundColor(AppColors.black)
                        .cornerRadius(9)
                    }
                    .padding(.top, 10)

                    Spacer()
                    
                    Button(action: saveSettings) {
                        HStack {
                            Image(systemName: "tray.and.arrow.down")
                            Text("Save")
                        }
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.white)
                        .foregroundColor(AppColors.black)
                        .cornerRadius(9)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(didPickDocuments: handleDocumentPicker)
            }
            .alert(isPresented: $showingSecretKeyAlert) {
                Alert(title: Text("Important"), message: Text("Important: Keep Your NFC Key Safe Please make a secure copy of your NFC key. This key is essential for restoring your passwords in case your NFC card is lost. It is crucial to keep this key in a very secure and private location, accessible only to you. Treating this key with the utmost confidentiality ensures the security of your sensitive information."), dismissButton: .default(Text("OK")))
            }
        }
    
    func saveSettings() {
        Config.shared.serverIPAddress = serverIPAddress
        Config.shared.serverPort = serverPort
        presentationMode.wrappedValue.dismiss()
    }
    
    func exportPasswords() {
        let passwords = passwordListViewModel.passwords
        
        if let jsonData = try? JSONEncoder().encode(passwords) {
            let filename = getDocumentsDirectory().appendingPathComponent("passwords.json")
            
            do {
                try jsonData.write(to: filename)
                
                let activityVC = UIActivityViewController(activityItems: [filename], applicationActivities: nil)
                if let topVC = UIApplication.shared.windows.first?.rootViewController {
                    if topVC.presentedViewController == nil {
                        topVC.present(activityVC, animated: true, completion: nil)
                    } else {
                        topVC.presentedViewController?.present(activityVC, animated: true, completion: nil)
                    }
                }
            } catch {
                print("Error writing JSON data to file: \(error)")
            }
        } else {
            print("Failed to encode passwords")
        }
    }
    
    func importPasswords() {
        showingDocumentPicker = true
    }
    
    func handleDocumentPicker(urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }

        guard selectedFileURL.startAccessingSecurityScopedResource() else {
            print("Couldn't access the security-scoped resource.")
            return
        }
        
        defer {
            selectedFileURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try Data(contentsOf: selectedFileURL)
            let importedPasswords = try JSONDecoder().decode([PasswordItem].self, from: data)
            
            passwordListViewModel.passwords.append(contentsOf: importedPasswords)
        } catch {
            print("Error importing passwords: \(error)")
        }
    }
    
    private func authenticateAndCopyNFCKey() {
           let context = LAContext()
           var error: NSError?
           
           if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
               context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Access requires authentication") { success, authenticationError in
                   DispatchQueue.main.async {
                       if success {
                           copyNFCKey()
                       } else {
                           nfcViewModel.alertMessage = "Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")"
                           nfcViewModel.showAlert = true
                       }
                   }
               }
           } else {
               nfcViewModel.alertMessage = "Biometric authentication not available: \(error?.localizedDescription ?? "Unknown reason")"
               nfcViewModel.showAlert = true
           }
       }

       func copyNFCKey() {
           nfcViewModel.startNFCSession(writing: false) { keyData, _ in
               guard let keyData = keyData else {
                   DispatchQueue.main.async {
                       nfcViewModel.alertMessage = "Failed to read key from NFC."
                       nfcViewModel.showAlert = true
                   }
                   return
               }
               let keyString = keyData.base64EncodedString()
               UIPasteboard.general.string = keyString
               showingSecretKeyAlert = true
           }
       }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(PasswordListViewModel())
            .environmentObject(NFCViewModel())
    }
}
