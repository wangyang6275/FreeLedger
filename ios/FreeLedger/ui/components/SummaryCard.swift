import SwiftUI

struct SummaryCard: View {
    let summary: TransactionSummary
    let currencyCode: String
    let monthTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(monthTitle)
                .font(AppTypography.body)
                .foregroundColor(.white.opacity(0.8))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(String(localized: "summary_expense_label"))
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.7))

                Text(AmountFormatter.format(summary.totalExpense, currencyCode: currencyCode))
                    .font(AppTypography.display)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }

            HStack(spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "summary_income_label"))
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(AmountFormatter.format(summary.totalIncome, currencyCode: currencyCode))
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "summary_balance_label"))
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(AmountFormatter.format(summary.balance, currencyCode: currencyCode))
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "a11y_summary \(AmountFormatter.format(summary.totalExpense, currencyCode: currencyCode)) \(AmountFormatter.format(summary.totalIncome, currencyCode: currencyCode)) \(AmountFormatter.format(summary.balance, currencyCode: currencyCode))")
        )
    }
}

#Preview {
    SummaryCard(
        summary: TransactionSummary(totalExpense: 250000, totalIncome: 800000),
        currencyCode: "CNY",
        monthTitle: "2月"
    )
    .padding()
}
