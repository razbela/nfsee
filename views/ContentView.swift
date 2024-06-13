import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NFCViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.navigateToPasswordList {
                    PasswordListView()
                        .environmentObject(viewModel)
                } else {
                    VStack {
                        Text("NFC INIT")
                            .font(.largeTitle)
                            .padding()
                    }
                    .onAppear {
                        viewModel.startNFCSession()
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("NFC Operation"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
