import SwiftUI

enum AppColors {
    // MARK: - 动态主题颜色（通过 ThemeManager 获取）
    @MainActor static var primary: Color { ThemeManager.shared.primary }
    @MainActor static var primaryDark: Color { ThemeManager.shared.primaryDark }
    @MainActor static var primaryLight: Color { ThemeManager.shared.primaryLight }
    @MainActor static var secondary: Color { ThemeManager.shared.secondary }
    @MainActor static var expense: Color { ThemeManager.shared.expense }
    @MainActor static var income: Color { ThemeManager.shared.income }
    @MainActor static var primaryGradient: LinearGradient { ThemeManager.shared.primaryGradient }
    
    // MARK: - 动态颜色（随外观模式变化）
    @MainActor static var background: Color {
        ThemeManager.shared.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FAFAFA")
    }
    @MainActor static var surface: Color {
        ThemeManager.shared.isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#FFFFFF")
    }
    @MainActor static var textPrimary: Color {
        ThemeManager.shared.isDarkMode ? Color(hex: "#F5F5F7") : Color(hex: "#2D3436")
    }
    @MainActor static var textSecondary: Color {
        ThemeManager.shared.isDarkMode ? Color(hex: "#ABABAB") : Color(hex: "#636E72")
    }
    @MainActor static var textTertiary: Color {
        ThemeManager.shared.isDarkMode ? Color(hex: "#8E8E93") : Color(hex: "#B2BEC3")
    }
    @MainActor static var divider: Color {
        ThemeManager.shared.isDarkMode ? Color(hex: "#3A3A3C") : Color(hex: "#F0F0F0")
    }
    static let success = Color(hex: "#00B894")
    static let warning = Color(hex: "#FDCB6E")
    static let error = Color(hex: "#E17055")
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
