import SwiftUI

struct AddPasswordView: View {
    @ObservedObject var viewModel: AddPasswordViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    
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
