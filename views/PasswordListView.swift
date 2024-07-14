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
                        HStack {
                            VStack(alignment: .leading) {
                                Text(password.title)
                                    .font(.headline)
                                Text(password.username)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Button(action: {
                                copyPasswordToClipboard(password)
                            }) {
                                Image(systemName: "document.on.document.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                                    .padding(.trailing, 15)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Button(action: {
                                passwordListViewModel.toggleEncryption(for: password)
                            }) {
                                Image(systemName: password.isDecrypted ? "lock.open.fill" : "lock.fill")
                                    .foregroundColor(password.isDecrypted ? Color.green : Color.red)
                                    .font(.system(size: 24))
                                    .padding(.trailing, 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(copiedPassword == password.password ? Color.gray.opacity(0.5) : Color.clear)
                        .background(Color.black.opacity(0.7))
                        .contentShape(Rectangle()) // Ensures that only the buttons are clickable
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
                })
                .sheet(isPresented: $showingAddPasswordView) {
                    let addPasswordViewModel = AddPasswordViewModel(delegate: passwordListViewModel)
                    AddPasswordView(viewModel: addPasswordViewModel)
                }
            }
            .alert(isPresented: $passwordListViewModel.showAlert) {
                Alert(title: Text("Message"), message: Text(passwordListViewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            
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
