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
                Text(L("summary_expense_label"))
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.7))

                Text(AmountFormatter.format(summary.totalExpense, currencyCode: currencyCode))
                    .font(AppTypography.display)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }

            HStack(spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("summary_income_label"))
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(AmountFormatter.format(summary.totalIncome, currencyCode: currencyCode))
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L("summary_balance_label"))
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
        .glassSummaryCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            L("a11y_summary %@ %@ %@", AmountFormatter.format(summary.totalExpense, currencyCode: currencyCode), AmountFormatter.format(summary.totalIncome, currencyCode: currencyCode), AmountFormatter.format(summary.balance, currencyCode: currencyCode))
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
