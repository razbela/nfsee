import SwiftUI

struct AppColors {
    static let red = Color(hex: "EE4E4E")
    static let green = Color(hex: "A1DD70")
    static let black = Color(hex: "000411")
    static let blue = Color(hex: "59619B")
    static let white = Color(hex: "FCF8F3")
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
