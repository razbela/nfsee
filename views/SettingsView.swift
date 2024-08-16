import SwiftUI
import UIKit

struct SettingsView: View {
    @State private var serverIPAddress: String = Config.shared.serverIPAddress
    @State private var serverPort: String = Config.shared.serverPort
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var passwordListViewModel: PasswordListViewModel
    @State private var showingDocumentPicker = false
    
    var body: some View {
        ZStack {
            AppColors.black.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .foregroundColor(AppColors.white)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    TextField("Server IP Address", text: $serverIPAddress)
                        .padding()
                        .background(AppColors.white)
                        .cornerRadius(6)
                        .foregroundColor(AppColors.black)
                        .padding(.horizontal)
                    
                    TextField("Server Port", text: $serverPort)
                        .padding()
                        .background(AppColors.white)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                        .foregroundColor(AppColors.black)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                Button(action: exportPasswords) {
                    HStack {
                        Image(systemName: "square.and.arrow.up") // Export icon
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
                        Image(systemName: "square.and.arrow.down") // Import icon
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
                
                Spacer() // Push the Save button to the bottom
                
                Button(action: saveSettings) {
                    HStack {
                        Image(systemName: "tray.and.arrow.down") // Save icon
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
                .padding(.bottom, 20) // Add padding to the bottom
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(didPickDocuments: handleDocumentPicker)
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

        // Start accessing the security-scoped resource
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
            
            // POST passwords to remote vault using NetworkService
            for password in importedPasswords {
                NetworkService.shared.addPassword(password) { success, error in
                    if success {
                        DispatchQueue.main.async {
                            // Save passwords to local vault
                            passwordListViewModel.passwords.append(password)
                        }
                    } else {
                        print("Failed to post password to remote vault: \(error ?? "Unknown error")")
                    }
                }
            }
        } catch {
            print("Error importing passwords: \(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(PasswordListViewModel())
    }
}
