import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    let settingsRepository: SettingsRepositoryProtocol
    @Environment(\.dismiss) private var dismiss

    private let currencies = ["CNY", "USD", "EUR", "GBP", "JPY", "KRW", "HKD", "TWD"]

    var body: some View {
        List {
            ForEach(currencies, id: \.self) { code in
                Button {
                    selectedCurrency = code
                    try? settingsRepository.set(key: "currency", value: code)
                    dismiss()
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        Text(currencySymbol(code))
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 32)
                            .foregroundColor(AppColors.textSecondary)

                        Text(currencyDisplayName(code))
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if selectedCurrency == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
        }
        .navigationTitle(L("settings_currency"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func currencyDisplayName(_ code: String) -> String {
        let locale = Locale.current
        let name = locale.localizedString(forCurrencyCode: code) ?? code
        return "\(code) - \(name)"
    }

    private func currencySymbol(_ code: String) -> String {
        switch code {
        case "CNY": return "¥"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "KRW": return "₩"
        case "HKD": return "HK$"
        case "TWD": return "NT$"
        default: return code
        }
    }
}
