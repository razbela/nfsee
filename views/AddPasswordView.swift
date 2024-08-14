import SwiftUI
import Navajo_Swift

struct AddPasswordView: View {
    @ObservedObject var viewModel: AddPasswordViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    @State private var passwordStrength: PasswordStrength = .veryWeak
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background shapes
                GeometryReader { geometry in
                    VStack {
                        RoundedRectangle(cornerRadius: 25.0)
                            .fill(AppColors.red)
                            .frame(width: geometry.size.width * 1.5, height: geometry.size.height * 0.100)
                            .position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top + geometry.size.height * 0.04)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 25.0)
                            .fill(AppColors.green)
                            .frame(width: geometry.size.width * 1.2, height: geometry.size.height * 0.625)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.75)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                // Form content on top
                Form {
                    Section(header: Text("Password Details").foregroundColor(AppColors.black)) {
                        TextField("Title", text: $title)
                        TextField("Username", text: $username)
                        SecureField("Password", text: $password)
                            .onChange(of: password) { newPassword in
                                withAnimation {
                                    passwordStrength = Navajo.strength(ofPassword: newPassword)
                                }
                            }
                        
                        // Password Strength Indicator
                        if !password.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Password Strength: \(passwordStrengthText)")
                                    .foregroundColor(passwordStrengthColor)
                                    .animation(.easeInOut, value: passwordStrengthColor)
                                
                                ProgressView(value: passwordStrengthProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: passwordStrengthColor))
                                    .animation(.easeInOut, value: passwordStrengthProgress)
                                
                                // Suggestion if password is weak
                                if passwordStrength == .veryWeak || passwordStrength == .weak {
                                    Text("Try using a longer password with a mix of letters, numbers, and symbols.")
                                        .font(.footnote)
                                        .foregroundColor(.red)
                                        .transition(.slide)
                                }
                            }
                            .padding(.top, 10)
                        } else {
                            ProgressView(value: 0.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                        }
                    }
                    .listRowBackground(AppColors.white) // Set the background color of the form rows
                }
                .cornerRadius(10)
                .padding()
                .navigationBarTitle("Add Password", displayMode: .inline)
                .navigationBarItems(leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(AppColors.black),
                trailing: Button("Save") {
                    let passwordItem = PasswordItem(title: title, username: username, password: password)
                    viewModel.addPassword(passwordItem)
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(AppColors.black))
            }
        }
    }
    
    // Helper computed properties for password strength
    var passwordStrengthText: String {
        switch passwordStrength {
        case .veryWeak: return "Very Weak"
        case .weak: return "Weak"
        case .reasonable: return "Reasonable"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
    
    var passwordStrengthColor: Color {
        switch passwordStrength {
        case .veryWeak: return AppColors.red
        case .weak: return .orange
        case .reasonable: return .yellow
        case .strong: return AppColors.green
        case .veryStrong: return .blue
        }
    }
    
    var passwordStrengthProgress: Double {
        if password.isEmpty {
            return 0.0
        }
        switch passwordStrength {
        case .veryWeak: return 0.2
        case .weak: return 0.4
        case .reasonable: return 0.6
        case .strong: return 0.8
        case .veryStrong: return 1.0
        }
    }
}

struct AddPasswordViewWrapper: View {
    @StateObject private var addPasswordViewModel = AddPasswordViewModel(delegate: PasswordListViewModel())

    var body: some View {
        AddPasswordView(viewModel: addPasswordViewModel)
    }
}

struct AddPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        AddPasswordViewWrapper()
    }
}
