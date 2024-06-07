import Foundation
import UIKit

struct PasswordItem: Identifiable {
    var id: UUID = UUID()
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
}
