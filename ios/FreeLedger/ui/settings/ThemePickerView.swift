import SwiftUI

struct ThemePickerView: View {
    @State private var themeManager = ThemeManager.shared
    
    var body: some View {
        List {
            ForEach(AppTheme.allCases) { theme in
                ThemeRow(
                    theme: theme,
                    isSelected: themeManager.currentTheme == theme,
                    onSelect: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.currentTheme = theme
                        }
                    }
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(GlassPageBackground())
        .navigationTitle(L("settings_theme"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ThemePreviewCircles(colors: theme.colors, isGlass: theme == .liquidGlass)
                
                Text(L(theme.nameKey))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(hex: theme.colors.primary))
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ThemePreviewCircles: View {
    let colors: ThemeColors
    var isGlass: Bool = false
    
    var body: some View {
        if isGlass {
            // 液态玻璃主题特殊预览：渐变圆 + 毛玻璃叠加
            ZStack {
                HStack(spacing: -8) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: colors.gradientStart), Color(hex: colors.gradientEnd)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Circle()
                        .fill(Color(hex: colors.secondary).opacity(0.6))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                        )
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                }
            }
        } else {
            HStack(spacing: -8) {
                Circle()
                    .fill(Color(hex: colors.primary))
                    .frame(width: 28, height: 28)
                Circle()
                    .fill(Color(hex: colors.secondary))
                    .frame(width: 28, height: 28)
                Circle()
                    .fill(Color(hex: colors.primaryLight))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: colors.primary).opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
    }
}
