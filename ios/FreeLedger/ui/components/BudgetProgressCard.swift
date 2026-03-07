import SwiftUI

struct BudgetProgressCard: View {
    let overallBudget: Budget?
    let spent: Int64
    let currencyCode: String

    private var percentage: Double {
        guard let budget = overallBudget, budget.amount > 0 else { return 0 }
        return Double(spent) / Double(budget.amount)
    }

    private var isOver: Bool {
        guard let budget = overallBudget else { return false }
        return spent > budget.amount
    }

    var body: some View {
        if let budget = overallBudget {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(progressColor)
                    Text(L("budget_progress_title"))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("\(Int(min(percentage, 1.0) * 100))%")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(progressColor)
                        .fontWeight(.semibold)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.divider)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geo.size.width * min(percentage, 1.0), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: percentage)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(L("budget_spent_of %@ %@",
                           AmountFormatter.format(spent, currencyCode: currencyCode),
                           AmountFormatter.format(budget.amount, currencyCode: currencyCode)))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    if isOver {
                        Text(L("budget_over %@", AmountFormatter.format(spent - budget.amount, currencyCode: currencyCode)))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                    } else {
                        Text(L("budget_remaining %@", AmountFormatter.format(budget.amount - spent, currencyCode: currencyCode)))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.success)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .glassCard()
        }
    }

    private var progressColor: Color {
        if percentage > 1.0 { return AppColors.error }
        if percentage > 0.8 { return AppColors.warning }
        return AppColors.primary
    }
}
