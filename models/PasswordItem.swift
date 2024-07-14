import Foundation
import UIKit

struct PasswordItem: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var username: String
    var password: String
    var isDecrypted: Bool = false
    
    init(title: String, username: String, password: String) {
           self.id = UUID()
           self.title = title
           self.username = username
           self.password = password
       }
    
    // Equatable and Hashable conformances
        static func == (lhs: PasswordItem, rhs: PasswordItem) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
}
