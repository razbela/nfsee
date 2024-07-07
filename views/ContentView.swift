import SwiftUI

struct ContentView: View {
    @StateObject private var nfcViewModel = NFCViewModel()
    @StateObject private var passwordListViewModel = PasswordListViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if nfcViewModel.navigateToPasswordList {
                    PasswordListView()
                        .environmentObject(passwordListViewModel)
                        .environmentObject(nfcViewModel)
                } else {
                    VStack {
                        Text("NFC INIT")
                            .font(.largeTitle)
                            .padding()
                        Button("Start NFC Session") {
                            nfcViewModel.writeKeyToNFC()
                        }
                    }
                    .onAppear {
                        // Delay the NFC initialization to ensure the view is fully loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            nfcViewModel.writeKeyToNFC()
                        }
                    }
                }
            }
            .alert(isPresented: $nfcViewModel.showAlert) {
                Alert(title: Text("NFC Operation"), message: Text(nfcViewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
