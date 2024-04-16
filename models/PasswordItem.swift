import Foundation
import UIKit

struct PasswordItem: Identifiable {
    var id: UUID = UUID()
    var logo: UIImage
    var title: String
    var username: String
    var password: String
    var url: String
    var isDecrypted: Bool = false
}
