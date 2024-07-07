import SwiftUI

struct PasswordListView: View {
    @EnvironmentObject var passwordListViewModel: PasswordListViewModel
    @EnvironmentObject var nfcViewModel: NFCViewModel
    @State private var showingAddPasswordView = false

    var body: some View {
        VStack {
            List {
                ForEach(passwordListViewModel.passwords) { password in
                    VStack(alignment: .leading) {
                        Text(password.title)
                            .font(.headline)
                        Text(password.username)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(password.isDecrypted ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                    .cornerRadius(10)
                }
                .onDelete(perform: passwordListViewModel.deletePasswords)
                .onMove(perform: passwordListViewModel.movePasswords)
            }
            .navigationTitle("Passwords")
            .navigationBarItems(leading: EditButton(), trailing: HStack {
                Button(action: {
                    showingAddPasswordView = true
                }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    passwordListViewModel.toggleNFCListening()
                }) {
                    Image(systemName: passwordListViewModel.isListening ? "lock.open" : "lock")
                }
            })
            .sheet(isPresented: $showingAddPasswordView) {
                let addPasswordViewModel = AddPasswordViewModel(delegate: passwordListViewModel)
                AddPasswordView(viewModel: addPasswordViewModel)
            }
        }
        .alert(isPresented: $passwordListViewModel.showAlert) {
            Alert(title: Text("Message"), message: Text(passwordListViewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}
