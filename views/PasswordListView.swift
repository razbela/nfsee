import SwiftUI

struct PasswordListView: View {
    @EnvironmentObject var nfcViewModel: NFCViewModel
    @StateObject private var viewModel = PasswordListViewModel()
    @State private var showingAddPasswordView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.passwords) { password in
                    VStack(alignment: .leading) {
                        Text(password.title)
                            .font(.headline)
                        Text(password.username)
                            .font(.subheadline)
                    }
                }
                .onDelete(perform: viewModel.deletePasswords)
                .onMove(perform: viewModel.movePasswords)
            }
            .navigationTitle("Passwords")
            .navigationBarItems(leading: EditButton(), trailing: Button(action: {
                showingAddPasswordView = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddPasswordView) {
                AddPasswordView(viewModel: viewModel)
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // Access nfcViewModel.keyData here if needed
            print("NFC Key Data: \(nfcViewModel.keyData ?? "No Key Data")")
        }
    }
}
