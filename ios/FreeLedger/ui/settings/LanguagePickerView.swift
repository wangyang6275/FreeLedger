import SwiftUI

struct LanguagePickerView: View {
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        List {
            ForEach(LanguageManager.supportedLanguages) { lang in
                Button {
                    languageManager.currentLanguage = lang.code
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.localName)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                            Text(lang.name)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        if languageManager.currentLanguage == lang.code {
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
        .navigationTitle(L("settings_language"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
