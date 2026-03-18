import SwiftUI

struct AppearancePickerView: View {
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        List {
            ForEach(AppearanceMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        themeManager.appearanceMode = mode
                    }
                } label: {
                    HStack {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 28)

                        Text(L(mode.nameKey))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        if themeManager.appearanceMode == mode {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(GlassPageBackground())
        .navigationTitle(L("settings_appearance"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
