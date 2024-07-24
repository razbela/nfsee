import SwiftUI

struct SettingsView: View {
    @State private var serverIPAddress: String = Config.shared.serverIPAddress
    @State private var serverPort: String = Config.shared.serverPort
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            AppColors.black.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .foregroundColor(AppColors.white)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    TextField("Server IP Address", text: $serverIPAddress)
                        .padding()
                        .background(AppColors.white)
                        .cornerRadius(6)
                        .foregroundColor(AppColors.black)
                        .padding(.horizontal)
                    
                    TextField("Server Port", text: $serverPort)
                        .padding()
                        .background(AppColors.white)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                        .foregroundColor(AppColors.black)
                        .padding(.horizontal)
                }
                
                Button(action: saveSettings) {
                    Text("Save")
                        .font(.title)
                        .padding()
                        .background(AppColors.blue)
                        .foregroundColor(AppColors.white)
                        .cornerRadius(11)
                        .fixedSize()
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    func saveSettings() {
        Config.shared.serverIPAddress = serverIPAddress
        Config.shared.serverPort = serverPort
        presentationMode.wrappedValue.dismiss()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
