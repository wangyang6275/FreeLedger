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
                ThemePreviewCircles(colors: theme.colors)
                
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
    
    var body: some View {
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

#Preview {
    NavigationStack {
        ThemePickerView()
    }
}
