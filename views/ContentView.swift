import SwiftUI

struct ContentView: View {
    @State private var passwords = [PasswordItem]()
    @State private var showingAddPasswordView = false
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(passwords) { password in
                    VStack(alignment: .leading) {
                        Text(password.title)
                            .font(.headline)
                        Text(password.username)
                            .font(.subheadline)
                    }
                }
                .onDelete(perform: deletePasswords)
                .onMove(perform: movePasswords)
            }
            .navigationTitle("Passwords")
            .navigationBarItems( leading: EditButton(),
                                 trailing: Button(action: {
                showingAddPasswordView = true
            }) {
                Image(systemName: "plus")
            }
            .sheet(isPresented: $showingAddPasswordView) {
                AddPasswordView(passwords: $passwords)
            })
        }
    }
    private func deletePasswords(at offsets: IndexSet) {
           passwords.remove(atOffsets: offsets)
       }
       
       private func movePasswords(from source: IndexSet, to destination: Int) {
           passwords.move(fromOffsets: source, toOffset: destination)
       }
}
