import SwiftUI

struct PasswordListView: View {
    @EnvironmentObject var passwordListViewModel: PasswordListViewModel
    @EnvironmentObject var nfcViewModel: NFCViewModel
    @State private var showingAddPasswordView = false
    @State private var copiedPassword: String? = nil

    var body: some View {
        ZStack {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(password.isDecrypted ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                        .cornerRadius(10)
                        .onTapGesture {
                            copyPasswordToClipboard(password)
                        }
                        .background(copiedPassword == password.password ? Color.gray.opacity(0.5) : Color.clear)
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
                        Image(systemName: passwordListViewModel.isDecrypted ? "lock.open" : "lock")
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
            
            // Footer alert
            if let copiedPassword = copiedPassword {
                VStack {
                    Spacer()
                    Text("Password copied to clipboard")
                        .font(.footnote)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .transition(.slide)
                        .animation(.easeInOut)
                }
                .padding()
            }
        }
    }

    private func copyPasswordToClipboard(_ password: PasswordItem) {
        let pasteboard = UIPasteboard.general
        let copiedText = password.isDecrypted ? password.password : password.password
        pasteboard.string = copiedText
        
        copiedPassword = password.password
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                copiedPassword = nil
            }
        }
    }
}
