import SwiftUI

struct AddPasswordView: View {
    @Binding var passwords: [PasswordItem]
    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    @State private var showingNFCAlert = false
    @State private var nfcService = NFCService()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Title", text: $title)
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
            }
            Button(action: addPassword) {
                Text("Add Password")
            }
        }
        .navigationTitle("Add Password")
        //.alert(isPresented: $showingNFCAlert) {
        //    Alert(title: Text("NFC Key"), message: Text("Hold your NFC tag near the iPhone."), dismissButton: .default(Text("OK")))
       // }
    }
    
    private func addPassword() {
        //showingNFCAlert = true
        //nfcService.readKey { key in
        //    guard let key = key else { return }
            let newPassword = PasswordItem(title: title, username: username, password: password)
            passwords.append(newPassword)
            presentationMode.wrappedValue.dismiss()
           // if let encryptedPassword = try? EncryptionService.encrypt(data: Data(newPassword.password.utf8), key: key) {
             //   var encryptedPasswordItem = newPassword
              //  encryptedPasswordItem.password = encryptedPassword.base64EncodedString()
              //  passwords.append(encryptedPasswordItem)
                // Save encryptedPasswordItem to persistence
            //}
        }
}
