import SwiftUI

struct TransactionCard: View {
    let transaction: Transaction
    let category: Category?
    let currencyCode: String

    private var isExpense: Bool {
        transaction.type == TransactionType.expense.rawValue
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            categoryIconView

            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName)
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(AppTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(isExpense ? AppColors.expense : AppColors.income)

                Text(AppDateFormatter.formatTime(transaction.createdAt))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(minHeight: 64)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var categoryIconView: some View {
        CategoryIconView(
            iconName: category?.iconName ?? "",
            colorHex: category?.colorHex ?? "#E0E0E0",
            size: 40,
            iconSize: 20
        )
    }

    private var categoryName: String {
        guard let cat = category else { return "—" }
        return String(localized: String.LocalizationValue(cat.nameKey))
    }

    private var amountText: String {
        let prefix = isExpense ? "-" : "+"
        return prefix + AmountFormatter.format(transaction.amount, currencyCode: currencyCode)
    }

    private var accessibilityText: String {
        let name = categoryName
        let amount = AmountFormatter.format(transaction.amount, currencyCode: currencyCode)
        let note = transaction.note ?? ""
        let time = AppDateFormatter.formatTime(transaction.createdAt)
        if note.isEmpty {
            return "\(name)，\(amount)，\(time)"
        }
        return "\(name)，\(amount)，\(note)，\(time)"
    }
}
