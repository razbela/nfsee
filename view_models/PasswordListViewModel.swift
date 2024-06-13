import Foundation
import SwiftUI

class PasswordListViewModel: ObservableObject {
    @Published var passwords = [PasswordItem]()
    @Published var showAlert = false
    @Published var alertMessage = ""

    func addPassword(_ password: PasswordItem) {
        passwords.append(password)
    }

    func deletePasswords(at offsets: IndexSet) {
        passwords.remove(atOffsets: offsets)
    }

    func movePasswords(from source: IndexSet, to destination: Int) {
        passwords.move(fromOffsets: source, toOffset: destination)
    }
}
