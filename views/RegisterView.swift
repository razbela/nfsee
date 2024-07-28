import SwiftUI

struct RegisterView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @Binding var isRegistering: Bool
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var nfcViewModel: NFCViewModel
    @State private var isRegisteringAttempt = false  

    var body: some View {
        ZStack {
            AppColors.green.edgesIgnoringSafeArea(.all)
            Circle()
                .scale(1.85)
                .foregroundColor(AppColors.red)
            Circle()
                .scale(1.5)
                .foregroundColor(AppColors.white)
            VStack {
                Image(systemName: "person.badge.plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .padding()
                    .foregroundColor(AppColors.red)
                
                VStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        if username.isEmpty {
                            Text("Username")
                                .foregroundColor(AppColors.black.opacity(0.5))
                                .padding(7)
                        }
                        TextField("", text: $username)
                            .padding(7)
                            .background(AppColors.white)
                            .cornerRadius(6)
                            .shadow(radius: 2)
                            .foregroundColor(AppColors.black)
                            .font(.system(size: 18, weight: .medium))
                            .padding(3)
                    }
                    ZStack(alignment: .leading) {
                        if password.isEmpty {
                            Text("Password")
                                .foregroundColor(AppColors.black.opacity(0.5))
                                .padding(7)
                        }
                        SecureField("", text: $password)
                            .padding(7)
                            .background(AppColors.white)
                            .cornerRadius(6)
                            .shadow(radius: 2)
                            .foregroundColor(AppColors.black)
                            .font(.system(size: 18, weight: .medium))
                            .padding(3)
                    }
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(AppColors.red)
                        .padding()
                }
                
                Button(action: startRegistration) {
                    Text("Register")
                        .font(.title3)
                        .padding(10)
                        .background(AppColors.black)
                        .foregroundColor(AppColors.white)
                        .cornerRadius(4)
                }
                .padding()
                .disabled(isRegisteringAttempt)  // Disable button if registration is in progress
                
                Button(action: {
                    isRegistering.toggle()
                }) {
                    Text("Already have an account? Login")
                        .foregroundColor(AppColors.black)
                }
                .padding()
            }
            .padding()
        }
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
        guard !isRegisteringAttempt else { return }  // Prevent multiple registration attempts
        
        isRegisteringAttempt = true  // Set flag to true to indicate registration is in progress
        
        nfcViewModel.startNFCSession(writing: true) { _, uid in  // Start NFC session to get UID
            if let uid = uid {
                completeRegistration(nfcUid: uid)
            } else {
                errorMessage = "Failed to read NFC UID."
                isRegisteringAttempt = false  // Reset flag if NFC UID read fails
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
            isRegisteringAttempt = false  // Reset flag if serialization fails
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during registration: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error during registration: \(error.localizedDescription)"
                }
                isRegisteringAttempt = false  // Reset flag if network error occurs
                return
            }
            
            guard let data = data else {
                isRegisteringAttempt = false  // Reset flag if no data received
                return
            }
            
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
                        self.errorMessage = "Registration failed: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                    }
                }
            }
            isRegisteringAttempt = false  // Reset flag after registration attempt completes
        }.resume()
    }
}

struct RegisterViewWrapper: View {
    @State private var isRegistering = true
    @State private var isLoggedIn = false
    @StateObject private var nfcViewModel = NFCViewModel() // Assuming you have a NFCViewModel class/struct
    
    var body: some View {
        RegisterView(isRegistering: $isRegistering, isLoggedIn: $isLoggedIn)
            .environmentObject(nfcViewModel)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterViewWrapper()
    }
}
