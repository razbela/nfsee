import SwiftUI

struct PasswordListView: View {
    @EnvironmentObject var passwordListViewModel: PasswordListViewModel
    @State private var showingAddPasswordView = false
    @State private var copiedPassword: String? = nil
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    List {
                        ForEach(passwordListViewModel.passwords) { password in
                            HStack {
                                VStack(alignment: .leading) {
                                    if isPasswordVisible {
                                        Text(password.username)
                                            .font(.headline)
                                            .padding(.bottom, 3)
                                            .foregroundColor(AppColors.white)
                                        Text(password.password)
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.white)
                                    } else {
                                        Text(password.title)
                                            .font(.headline)
                                            .padding(.bottom, 3)
                                            .foregroundColor(AppColors.white)
                                        Text(password.username)
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.white)
                                    }
                                }
                                Spacer()
                                .buttonStyle(PlainButtonStyle())
                                Button(action: {
                                    copyPasswordToClipboard(password)
                                }) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 22))
                                        .padding(.trailing, 5)
                                }
                                
                                .buttonStyle(PlainButtonStyle())
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 22))
                                        .padding(.trailing, 5)
                                        
                                }
                                .buttonStyle(PlainButtonStyle())
                                Button(action: {
                                    passwordListViewModel.toggleEncryption(for: password) { success in
                                        if success {
                                            withAnimation(.bouncy) {
                                                // The state change will automatically animate due to @Published
                                            }
                                        }
                                    }
                                }) {
                                    Image(systemName: password.isDecrypted ? "lock.open.fill" : "lock.fill")
                                        .foregroundColor(password.isDecrypted ? AppColors.green : AppColors.red)
                                        .font(.system(size: 22))
                                }
                            }
                            .padding()
                            .background(AppColors.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(password.isDecrypted ? AppColors.green : AppColors.red, lineWidth: 10)
                            )
                            .contentShape(Rectangle()) // Ensures that only the buttons are clickable
                        }
                        .onDelete(perform: passwordListViewModel.deletePasswords)
                        .onMove(perform: passwordListViewModel.movePasswords)
                    }
                    .navigationTitle("Passwords")
                    .navigationBarItems(leading: EditButton().foregroundColor(AppColors.black), trailing: HStack {
                        Button(action: {
                            showingAddPasswordView = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(AppColors.black)
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
                            .background(AppColors.black.opacity(0.7))
                            .cornerRadius(10)
                            .foregroundColor(AppColors.white)
                            .transition(.slide)
                            .animation(.easeInOut)
                    }
                    .padding()
                }
            }
        }
    }

    private func copyPasswordToClipboard(_ password: PasswordItem) {
        let pasteboard = UIPasteboard.general
        let copiedText = password.isDecrypted ? password.password : password.password
        pasteboard.string = copiedText
        
        copiedPassword = password.password
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut) {
                copiedPassword = nil
            }
        }
    }
}

struct PasswordListViewWrapper: View {
    @StateObject private var passwordListViewModel = PasswordListViewModel()

    var body: some View {
        PasswordListView()
            .environmentObject(passwordListViewModel)
            .onAppear {
                // Adding example data
                let examplePasswords = [
                    PasswordItem(title: "Example 1", username: "user1", password: "password1"),
                    PasswordItem(title: "Example 2", username: "user2", password: "password2"),
                    PasswordItem(title: "Example 3", username: "user3", password: "password3")
                ]
                for password in examplePasswords {
                    passwordListViewModel.addPassword(password)
                }
            }
    }
}

struct PasswordListView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordListViewWrapper()
    }
}
