import SwiftUI

enum AppColors {
    static let primary = Color(hex: "#FF6B6B")
    static let primaryDark = Color(hex: "#E55A5A")
    static let primaryLight = Color(hex: "#FFE8E8")
    static let secondary = Color(hex: "#4ECDC4")
    static let background = Color(hex: "#FAFAFA")
    static let surface = Color(hex: "#FFFFFF")
    static let textPrimary = Color(hex: "#2D3436")
    static let textSecondary = Color(hex: "#636E72")
    static let textTertiary = Color(hex: "#B2BEC3")
    static let divider = Color(hex: "#F0F0F0")
    static let success = Color(hex: "#00B894")
    static let warning = Color(hex: "#FDCB6E")
    static let error = Color(hex: "#E17055")

    static let expense = primary
    static let income = secondary

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#FF6B6B"), Color(hex: "#FF8E8E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
