import SwiftUI

struct SettingsView: View {
    @State private var serverIPAddress: String = Config.shared.serverIPAddress
    @State private var serverPort: String = Config.shared.serverPort
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .padding()

            TextField("Server IP Address", text: $serverIPAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Server Port", text: $serverPort)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: saveSettings) {
                Text("Save")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
    
    func saveSettings() {
        Config.shared.serverIPAddress = serverIPAddress
        Config.shared.serverPort = serverPort
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
