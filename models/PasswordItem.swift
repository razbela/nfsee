import Foundation

struct PasswordItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var username: String
    var password: String
    var url: String
    var isDecrypted: Bool = false
}
