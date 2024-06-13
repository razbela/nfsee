import SwiftUI

struct AddPasswordView: View {
    @ObservedObject var viewModel: PasswordListViewModel
    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
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
        }
    }
    
    private func addPassword() {
        let newPassword = PasswordItem(title: title, username: username, password: password)
        viewModel.addPassword(newPassword)
        presentationMode.wrappedValue.dismiss()
    }
}
