import SwiftUI

struct PasswordListView: View {
    @EnvironmentObject var passwordListViewModel: PasswordListViewModel
    @State private var showingAddPasswordView = false
    @State private var copiedPassword: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    List {
                        ForEach(passwordListViewModel.passwords) { password in
                            HStack {
                                VStack(alignment: .leading) {
                                    if password.isDecrypted && (passwordListViewModel.passwordVisibility[password.id] ?? false) {
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

                                // Show countdown timer if the password is decrypted
                                if password.isDecrypted {
                                    if let remainingTime = passwordListViewModel.remainingTime[password.id], remainingTime > 0 {
                                                                Text("\(remainingTime)")
                                                                .foregroundColor(AppColors.white)
                                                                .font(.system(size: 22))
                                                                .padding(.trailing, 12)
                                            }
                                    
                                    Button(action: {
                                        // Toggle visibility
                                        passwordListViewModel.passwordVisibility[password.id] = !(passwordListViewModel.passwordVisibility[password.id] ?? false)
                                    }) {
                                        Image(systemName: (passwordListViewModel.passwordVisibility[password.id] ?? false) ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 22))
                                            .padding(.trailing, 5)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    // Copy button
                                    Button(action: {
                                        copyPasswordToClipboard(password)
                                    }) {
                                        Image(systemName: "doc.on.doc.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 22))
                                            .padding(.trailing, 5)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }

                                // Lock or unlock button
                                Button(action: {
                                    toggleEncryption(for: password)
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
                            .contentShape(Rectangle())
                            .listRowBackground(Color.clear)
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
                    .onAppear {
                        passwordListViewModel.loadPasswords()
                    }
                    .sheet(isPresented: $showingAddPasswordView) {
                        AddPasswordView(viewModel: AddPasswordViewModel(delegate: passwordListViewModel))
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
        pasteboard.string = password.password

        copiedPassword = password.password

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut) {
                copiedPassword = nil
            }
        }
    }

    private func toggleEncryption(for password: PasswordItem) {
        passwordListViewModel.toggleEncryption(for: password) { success in
            if success {
                // View will update automatically due to @Published properties in ViewModel
            }
        }
    }
}
