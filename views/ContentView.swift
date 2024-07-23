import SwiftUI

struct ContentView: View {
    @StateObject private var nfcViewModel = NFCViewModel()
    @StateObject private var passwordListViewModel = PasswordListViewModel()
    @State private var isLoading = false
    @State private var isLoggedIn = false
    @State private var isRegistering = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoggedIn {
                    PasswordListView()
                        .environmentObject(passwordListViewModel)
                        .environmentObject(nfcViewModel)
                } else if isRegistering {
                    RegisterView(isRegistering: $isRegistering, isLoggedIn: $isLoggedIn)
                        .environmentObject(nfcViewModel)
                } else {
                    LoginView(isRegistering: $isRegistering, isLoggedIn: $isLoggedIn)
                        .environmentObject(nfcViewModel)
                }
            }
            .alert(isPresented: $nfcViewModel.showAlert) {
                Alert(title: Text("NFC Operation"), message: Text(nfcViewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationBarItems(trailing: Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gear")
                    .foregroundColor(AppColors.white)
                    .imageScale(.large)
            })
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}
