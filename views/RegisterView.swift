import SwiftUI

struct RegisterView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @Binding var isRegistering: Bool
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var nfcViewModel: NFCViewModel
    
    var body: some View {
        VStack {
            Text("Register")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(action: startRegistration) {
                Text("Register")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            Button(action: {
                isRegistering.toggle()
            }) {
                Text("Already have an account? Login")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
        .alert(isPresented: $nfcViewModel.showAlert) {
            Alert(title: Text("NFC Operation"), message: Text(nfcViewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
        .onReceive(nfcViewModel.$nfcUid) { uid in
            if let uid = uid {
                completeRegistration(nfcUid: uid)
            }
        }
    }

    func startRegistration() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill out both fields."
            return
        }
        nfcViewModel.startNFCSession(writing: true) { _, uid in  // Start NFC session to get UID
            if let uid = uid {
                completeRegistration(nfcUid: uid)
            } else {
                errorMessage = "Failed to read NFC UID."
            }
        }
    }

    func completeRegistration(nfcUid: String) {
        let registerData = ["username": username, "password": password, "nfc_uid": nfcUid]
        
        let ipAddress = Config.shared.serverIPAddress
        let port = Config.shared.serverPort
        
        guard let url = URL(string: "http://\(ipAddress):\(port)/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: registerData, options: [])
        } catch {
            print("Error serializing register data: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during registration: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    print("Registration successful: \(jsonResponse ?? [:])")
                    DispatchQueue.main.async {
                        self.nfcViewModel.alertMessage = "Registration successful!"
                        self.nfcViewModel.showAlert = true
                        self.isLoggedIn = true
                    }
                } catch {
                    print("Error parsing JSON response: \(error.localizedDescription)")
                }
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    DispatchQueue.main.async {
                        errorMessage = "Registration failed: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                    }
                }
            }
        }.resume()
    }
}
