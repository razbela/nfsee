import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @Binding var isRegistering: Bool
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var nfcViewModel: NFCViewModel
    @EnvironmentObject var passwordListViewModel: PasswordListViewModel

    var body: some View {
        ZStack {
            AppColors.red.edgesIgnoringSafeArea(.all)
            Circle()
                .scale(1.85)
                .foregroundColor(AppColors.green)
            Circle()
                .scale(1.5)
                .foregroundColor(AppColors.white)
            VStack {
                Image(systemName: isLoggedIn ? "lock.open.fill" : "lock.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .padding()
                    .foregroundColor(isLoggedIn ? .green : AppColors.red)
                
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(AppColors.white)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                        .foregroundColor(AppColors.black)
                        .font(.system(size: 18, weight: .medium))
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(AppColors.white)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                        .foregroundColor(AppColors.black)
                        .font(.system(size: 18, weight: .medium))
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(AppColors.red)
                        .padding()
                }
                
                Button(action: authenticateWithFaceID) {
                    Text("Login with Face ID")
                        .font(.title3)
                        .padding()
                        .background(AppColors.black)
                        .foregroundColor(AppColors.white)
                        .cornerRadius(4)
                }
                .padding()
                
                Button(action: {
                    isRegistering.toggle()
                }) {
                    Text("Don't have an account? Register")
                        .foregroundColor(AppColors.black)
                }
                .padding()
            }
            .padding()
        }
    }

    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Access requires authentication") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        login()
                    } else {
                        errorMessage = "Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")"
                    }
                }
            }
        } else {
            errorMessage = "Biometric authentication not available: \(error?.localizedDescription ?? "Unknown reason")"
        }
    }

    func login() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both username and password."
            return
        }

        let loginData = ["username": username, "password": password]
        let ipAddress = Config.shared.serverIPAddress
        let port = Config.shared.serverPort
        
        guard let url = URL(string: "http://\(ipAddress):\(port)/login") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData, options: [])
        } catch {
            print("Error serializing login data: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during login: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    errorMessage = "Error during login: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received from server."
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let token = jsonResponse["access_token"] as? String,
                       let passwordsData = jsonResponse["passwords"] as? [[String: Any]] {
                        DispatchQueue.main.async {
                            UserDefaults.standard.set(token, forKey: "jwtToken")
                            self.isLoggedIn = true
                            self.errorMessage = nil
                            
                            let decoder = JSONDecoder()
                            if let jsonData = try? JSONSerialization.data(withJSONObject: passwordsData, options: []),
                               let passwords = try? decoder.decode([PasswordItem].self, from: jsonData) {
                                self.passwordListViewModel.passwords = passwords
                            } else {
                                print("Failed to load passwords")
                            }
                        }
                    }
                } catch {
                    print("Error parsing JSON response: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        errorMessage = "Error parsing response: \(error.localizedDescription)"
                    }
                }
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    DispatchQueue.main.async {
                        errorMessage = "Login failed: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                    }
                }
            }
        }.resume()
    }
}
struct LoginViewWrapper: View {
    @State private var isRegistering = false
    @State private var isLoggedIn = false
    @StateObject private var nfcViewModel = NFCViewModel()
    @StateObject private var passwordListViewModel = PasswordListViewModel()

    var body: some View {
        LoginView(isRegistering: $isRegistering, isLoggedIn: $isLoggedIn)
            .environmentObject(nfcViewModel)
            .environmentObject(passwordListViewModel)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginViewWrapper()
    }
}

