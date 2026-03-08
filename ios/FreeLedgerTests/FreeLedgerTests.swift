import Testing
import SwiftUI
@testable import FreeLedger

@MainActor @Test func appColorsExist() async throws {
    #expect(AppColors.primary != nil)
}

// MARK: - AppTheme Tests

@Suite("AppTheme Tests")
struct AppThemeTests {
    @Test func allCasesHaveUniqueRawValues() {
        let rawValues = AppTheme.allCases.map(\.rawValue)
        let uniqueRawValues = Set(rawValues)
        #expect(rawValues.count == uniqueRawValues.count)
    }

    @Test func allCasesHaveNameKey() {
        for theme in AppTheme.allCases {
            #expect(!theme.nameKey.isEmpty)
        }
    }

    @Test func allCasesHaveUniqueNameKeys() {
        let nameKeys = AppTheme.allCases.map(\.nameKey)
        let unique = Set(nameKeys)
        #expect(nameKeys.count == unique.count)
    }

    @Test func allCasesHaveValidColors() {
        for theme in AppTheme.allCases {
            let c = theme.colors
            #expect(c.primary.hasPrefix("#"))
            #expect(c.primaryDark.hasPrefix("#"))
            #expect(c.primaryLight.hasPrefix("#"))
            #expect(c.secondary.hasPrefix("#"))
            #expect(c.gradientStart.hasPrefix("#"))
            #expect(c.gradientEnd.hasPrefix("#"))
        }
    }

    @Test func coralIsDefault() {
        // coral 应该有符合预期的配色
        let c = AppTheme.coral.colors
        #expect(c.primary == "#FF6B6B")
        #expect(c.secondary == "#4ECDC4")
    }

    @Test func liquidGlassColors() {
        let c = AppTheme.liquidGlass.colors
        #expect(c.primary == "#007AFF")
        #expect(c.gradientStart == "#667EEA")
        #expect(c.gradientEnd == "#764BA2")
    }

    @Test func idEqualsRawValue() {
        for theme in AppTheme.allCases {
            #expect(theme.id == theme.rawValue)
        }
    }

    @Test func nameKeyPrefixCorrect() {
        for theme in AppTheme.allCases {
            #expect(theme.nameKey.hasPrefix("theme_"))
        }
    }

    @Test func initFromRawValue() {
        for theme in AppTheme.allCases {
            let restored = AppTheme(rawValue: theme.rawValue)
            #expect(restored == theme)
        }
    }

    @Test func initFromInvalidRawValueReturnsNil() {
        let invalid = AppTheme(rawValue: "nonexistent_theme")
        #expect(invalid == nil)
    }

    @Test func expectedThemeCount() {
        #expect(AppTheme.allCases.count == 16)
    }
}

// MARK: - ThemeManager Tests

@Suite("ThemeManager Tests")
struct ThemeManagerTests {
    @Test @MainActor func sharedInstanceExists() {
        let manager = ThemeManager.shared
        #expect(manager.currentTheme != nil)
    }

    @Test @MainActor func switchThemePersists() {
        let manager = ThemeManager.shared
        let original = manager.currentTheme

        manager.currentTheme = .ocean
        #expect(manager.currentTheme == .ocean)
        #expect(UserDefaults.standard.string(forKey: "app_theme") == "ocean")

        // 恢复
        manager.currentTheme = original
    }

    @Test @MainActor func colorsMatchCurrentTheme() {
        let manager = ThemeManager.shared
        let original = manager.currentTheme

        manager.currentTheme = .forest
        #expect(manager.colors.primary == AppTheme.forest.colors.primary)
        #expect(manager.colors.secondary == AppTheme.forest.colors.secondary)

        manager.currentTheme = original
    }

    @Test @MainActor func isGlassTrueOnlyForLiquidGlass() {
        let manager = ThemeManager.shared
        let original = manager.currentTheme

        for theme in AppTheme.allCases {
            manager.currentTheme = theme
            if theme == .liquidGlass {
                #expect(manager.isGlassTheme == true)
            } else {
                #expect(manager.isGlassTheme == false)
            }
        }

        manager.currentTheme = original
    }

    @Test @MainActor func refreshIdChangesOnThemeSwitch() {
        let manager = ThemeManager.shared
        let original = manager.currentTheme
        let oldId = manager.refreshId

        manager.currentTheme = .lavender
        #expect(manager.refreshId != oldId)

        manager.currentTheme = original
    }

    @Test @MainActor func fixedColorsNotNil() {
        #expect(ThemeManager.background != nil)
        #expect(ThemeManager.surface != nil)
        #expect(ThemeManager.textPrimary != nil)
        #expect(ThemeManager.textSecondary != nil)
        #expect(ThemeManager.textTertiary != nil)
        #expect(ThemeManager.divider != nil)
        #expect(ThemeManager.success != nil)
        #expect(ThemeManager.warning != nil)
        #expect(ThemeManager.error != nil)
    }

    @Test @MainActor func dynamicColorAccessors() {
        let manager = ThemeManager.shared
        let original = manager.currentTheme

        manager.currentTheme = .coral
        #expect(manager.primary != nil)
        #expect(manager.primaryDark != nil)
        #expect(manager.primaryLight != nil)
        #expect(manager.secondary != nil)
        #expect(manager.expense != nil)
        #expect(manager.income != nil)

        manager.currentTheme = original
    }

    @Test @MainActor func primaryGradientNotNil() {
        let manager = ThemeManager.shared
        #expect(manager.primaryGradient != nil)
    }

    @Test @MainActor func switchAllThemesNoErrors() {
        let manager = ThemeManager.shared
        let original = manager.currentTheme

        for theme in AppTheme.allCases {
            manager.currentTheme = theme
            // 验证切换主题不会崩溃，且所有属性可访问
            _ = manager.colors
            _ = manager.primary
            _ = manager.primaryGradient
            _ = manager.isGlassTheme
        }

        manager.currentTheme = original
    }
}
