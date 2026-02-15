import SwiftUI

/// 预设主题类型
enum AppTheme: String, CaseIterable, Identifiable {
    case coral = "coral"           // 默认珊瑚红
    case forest = "forest"         // 森林绿
    case ocean = "ocean"           // 海洋蓝
    case lavender = "lavender"     // 薰衣草紫
    case charcoal = "charcoal"     // 商务灰
    case kids = "kids"             // 童趣乐园
    case student = "student"       // 学霸蓝
    case executive = "executive"   // 精英灰
    case homemaker = "homemaker"   // 温馨米
    case youngPro = "youngPro"     // 活力橙
    case sakura = "sakura"         // 樱花粉
    case zen = "zen"               // 禅意绿
    case moonlight = "moonlight"   // 月光银
    case autumn = "autumn"         // 秋意浓
    case bold = "bold"             // 锐意红
    
    var id: String { rawValue }
    
    /// 主题显示名称的本地化 key
    var nameKey: String {
        switch self {
        case .coral: return "theme_coral"
        case .forest: return "theme_forest"
        case .ocean: return "theme_ocean"
        case .lavender: return "theme_lavender"
        case .charcoal: return "theme_charcoal"
        case .kids: return "theme_kids"
        case .student: return "theme_student"
        case .executive: return "theme_executive"
        case .homemaker: return "theme_homemaker"
        case .youngPro: return "theme_youngpro"
        case .sakura: return "theme_sakura"
        case .zen: return "theme_zen"
        case .moonlight: return "theme_moonlight"
        case .autumn: return "theme_autumn"
        case .bold: return "theme_bold"
        }
    }
    
    /// 主题配色
    var colors: ThemeColors {
        switch self {
        case .coral:
            return ThemeColors(
                primary: "#FF6B6B",
                primaryDark: "#E55A5A",
                primaryLight: "#FFE8E8",
                secondary: "#4ECDC4",
                gradientStart: "#FF6B6B",
                gradientEnd: "#FF8E8E"
            )
        case .forest:
            return ThemeColors(
                primary: "#2ECC71",
                primaryDark: "#27AE60",
                primaryLight: "#E8F8F0",
                secondary: "#F39C12",
                gradientStart: "#2ECC71",
                gradientEnd: "#58D68D"
            )
        case .ocean:
            return ThemeColors(
                primary: "#3498DB",
                primaryDark: "#2980B9",
                primaryLight: "#EBF5FB",
                secondary: "#E74C3C",
                gradientStart: "#3498DB",
                gradientEnd: "#5DADE2"
            )
        case .lavender:
            return ThemeColors(
                primary: "#9B59B6",
                primaryDark: "#8E44AD",
                primaryLight: "#F5EEF8",
                secondary: "#1ABC9C",
                gradientStart: "#9B59B6",
                gradientEnd: "#AF7AC5"
            )
        case .charcoal:
            return ThemeColors(
                primary: "#34495E",
                primaryDark: "#2C3E50",
                primaryLight: "#EBF0F5",
                secondary: "#E67E22",
                gradientStart: "#34495E",
                gradientEnd: "#5D6D7E"
            )
        case .kids:
            return ThemeColors(
                primary: "#FF6F91",
                primaryDark: "#E55A7A",
                primaryLight: "#FFE8EE",
                secondary: "#FFC75F",
                gradientStart: "#FF6F91",
                gradientEnd: "#FF8FA5"
            )
        case .student:
            return ThemeColors(
                primary: "#5DADE2",
                primaryDark: "#3498DB",
                primaryLight: "#EBF5FB",
                secondary: "#48C9B0",
                gradientStart: "#5DADE2",
                gradientEnd: "#85C1E9"
            )
        case .executive:
            return ThemeColors(
                primary: "#2C3E50",
                primaryDark: "#1A252F",
                primaryLight: "#ECF0F1",
                secondary: "#E67E22",
                gradientStart: "#2C3E50",
                gradientEnd: "#34495E"
            )
        case .homemaker:
            return ThemeColors(
                primary: "#D4A574",
                primaryDark: "#B8935F",
                primaryLight: "#F5F0E8",
                secondary: "#A8D5BA",
                gradientStart: "#D4A574",
                gradientEnd: "#E0B886"
            )
        case .youngPro:
            return ThemeColors(
                primary: "#FF6348",
                primaryDark: "#E5543A",
                primaryLight: "#FFEBE8",
                secondary: "#FFD93D",
                gradientStart: "#FF6348",
                gradientEnd: "#FF7F6E"
            )
        case .sakura:
            return ThemeColors(
                primary: "#FFB6C1",
                primaryDark: "#FF9FAD",
                primaryLight: "#FFF0F3",
                secondary: "#DDA0DD",
                gradientStart: "#FFB6C1",
                gradientEnd: "#FFC8D1"
            )
        case .zen:
            return ThemeColors(
                primary: "#7CB342",
                primaryDark: "#689F38",
                primaryLight: "#F1F8E9",
                secondary: "#8D6E63",
                gradientStart: "#7CB342",
                gradientEnd: "#9CCC65"
            )
        case .moonlight:
            return ThemeColors(
                primary: "#78909C",
                primaryDark: "#607D8B",
                primaryLight: "#ECEFF1",
                secondary: "#64B5F6",
                gradientStart: "#78909C",
                gradientEnd: "#90A4AE"
            )
        case .autumn:
            return ThemeColors(
                primary: "#C17817",
                primaryDark: "#A86613",
                primaryLight: "#FFF4E6",
                secondary: "#8B4513",
                gradientStart: "#C17817",
                gradientEnd: "#D4902A"
            )
        case .bold:
            return ThemeColors(
                primary: "#DC143C",
                primaryDark: "#C41230",
                primaryLight: "#FFE8ED",
                secondary: "#FFD700",
                gradientStart: "#DC143C",
                gradientEnd: "#E6345A"
            )
        }
    }
}

/// 主题配色数据
struct ThemeColors {
    let primary: String
    let primaryDark: String
    let primaryLight: String
    let secondary: String
    let gradientStart: String
    let gradientEnd: String
}

/// 主题管理器
@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    private static let themeKey = "app_theme"
    
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.themeKey)
            refreshId = UUID()
        }
    }
    
    /// 用于强制刷新 UI
    var refreshId = UUID()
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.themeKey),
           let theme = AppTheme(rawValue: saved) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .coral
        }
    }
    
    /// 当前主题的配色
    var colors: ThemeColors {
        currentTheme.colors
    }
    
    // MARK: - 动态颜色访问
    
    var primary: Color { Color(hex: colors.primary) }
    var primaryDark: Color { Color(hex: colors.primaryDark) }
    var primaryLight: Color { Color(hex: colors.primaryLight) }
    var secondary: Color { Color(hex: colors.secondary) }
    
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: colors.gradientStart), Color(hex: colors.gradientEnd)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 固定颜色（不随主题变化）
    static let background = Color(hex: "#FAFAFA")
    static let surface = Color(hex: "#FFFFFF")
    static let textPrimary = Color(hex: "#2D3436")
    static let textSecondary = Color(hex: "#636E72")
    static let textTertiary = Color(hex: "#B2BEC3")
    static let divider = Color(hex: "#F0F0F0")
    static let success = Color(hex: "#00B894")
    static let warning = Color(hex: "#FDCB6E")
    static let error = Color(hex: "#E17055")
    
    var expense: Color { primary }
    var income: Color { secondary }
}
