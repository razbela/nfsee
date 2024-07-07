import SwiftUI

struct AddPasswordView: View {
    @ObservedObject var viewModel: AddPasswordViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Password Details")) {
                    TextField("Title", text: $title)
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                }
            }
            .navigationBarTitle("Add Password", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                let passwordItem = PasswordItem(title: title, username: username, password: password)
                viewModel.addPassword(passwordItem)
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
