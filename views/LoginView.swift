import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @Binding var isRegistering: Bool
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var nfcViewModel: NFCViewModel
    
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
                
                VStack(spacing: 16) {ZStack(alignment: .leading) {
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
                if password.isEmpty{
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
                
                Button(action: login) {
                    Text("Login")
                        .font(.title3) // Smaller font size
                        .padding(10) // Smaller padding
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
                return
            }
            
            guard let data = data else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    print("Login successful: \(jsonResponse ?? [:])")
                    DispatchQueue.main.async {
                        self.isLoggedIn = true
                    }
                } catch {
                    print("Error parsing JSON response: \(error.localizedDescription)")
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
    @StateObject private var nfcViewModel = NFCViewModel() // Assuming you have a NFCViewModel class/struct
    
    var body: some View {
        LoginView(isRegistering: $isRegistering, isLoggedIn: $isLoggedIn)
            .environmentObject(nfcViewModel)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginViewWrapper()
    }
}
