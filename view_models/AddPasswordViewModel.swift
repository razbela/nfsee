import Foundation
import SwiftUI

class AddPasswordViewModel: ObservableObject {
    weak var delegate: PasswordListDelegate?
    
    init(delegate: PasswordListDelegate?) {
        self.delegate = delegate
    }

    func addPassword(_ password: PasswordItem) {
        delegate?.addPassword(password)
    }
}
