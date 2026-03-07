import SwiftUI
import Charts

struct AnnualReportView: View {
    @State private var viewModel: AnnualReportViewModel

    init(transactionRepository: TransactionRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        _viewModel = State(initialValue: AnnualReportViewModel(
            transactionRepository: transactionRepository,
            settingsRepository: settingsRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                yearNavigator

                if viewModel.isEmpty {
                    emptyState
                } else {
                    overviewCards
                    monthlyChart
                    categoryBreakdownSection
                    insightsSection
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.background)
        .navigationTitle(L("annual_title"))
        .onAppear { viewModel.loadData() }
    }

    // MARK: - Year Navigator
    private var yearNavigator: some View {
        HStack {
            Button {
                viewModel.previousYear()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(AppColors.primary)
            }

            Spacer()

            Text(String(viewModel.currentYear))
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)
                .fontWeight(.bold)

            Spacer()

            Button {
                viewModel.nextYear()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text(L("annual_empty"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, AppSpacing.xxl)
    }

    // MARK: - Overview Cards
    private var overviewCards: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                summaryCard(
                    title: L("annual_total_expense"),
                    amount: viewModel.summary.totalExpense,
                    color: AppColors.expense
                )
                summaryCard(
                    title: L("annual_total_income"),
                    amount: viewModel.summary.totalIncome,
                    color: AppColors.income
                )
            }

            HStack(spacing: AppSpacing.sm) {
                summaryCard(
                    title: L("annual_net"),
                    amount: viewModel.netAmount,
                    color: viewModel.netAmount >= 0 ? AppColors.income : AppColors.expense
                )
                summaryCard(
                    title: L("annual_transactions"),
                    count: viewModel.transactionCount
                )
            }
        }
    }

    private func summaryCard(title: String, amount: Int64, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(AmountFormatter.format(amount, currencyCode: viewModel.currencyCode))
                .font(AppTypography.title2)
                .foregroundColor(color)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func summaryCard(title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Text("\(count)")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.primary)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Monthly Chart
    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(L("annual_monthly_trend"))
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            Chart(viewModel.monthlySummaries) { item in
                BarMark(
                    x: .value("Month", item.monthLabel),
                    y: .value("Amount", Double(item.expense) / 100.0)
                )
                .foregroundStyle(AppColors.expense.opacity(0.8))

                BarMark(
                    x: .value("Month", item.monthLabel),
                    y: .value("Amount", Double(item.income) / 100.0)
                )
                .foregroundStyle(AppColors.income.opacity(0.8))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(AmountFormatter.format(Int64(v * 100), currencyCode: viewModel.currencyCode))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 220)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Category Breakdown
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(L("annual_category_breakdown"))
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            ForEach(viewModel.expenseBreakdown.prefix(10)) { item in
                HStack(spacing: AppSpacing.sm) {
                    CategoryIconView(iconName: item.iconName, colorHex: item.colorHex, size: 32, iconSize: 16)

                    Text(item.categoryName)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(AmountFormatter.format(item.total, currencyCode: viewModel.currencyCode))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.medium)
                        Text(String(format: "%.1f%%", item.percentage))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: item.colorHex))
                        .frame(width: geo.size.width * min(item.percentage / 100.0, 1.0), height: 4)
                }
                .frame(height: 4)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Insights
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(L("annual_insights"))
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            insightRow(
                icon: "arrow.down.circle",
                title: L("annual_avg_expense"),
                value: AmountFormatter.format(viewModel.avgMonthlyExpense, currencyCode: viewModel.currencyCode),
                color: AppColors.expense
            )
            insightRow(
                icon: "arrow.up.circle",
                title: L("annual_avg_income"),
                value: AmountFormatter.format(viewModel.avgMonthlyIncome, currencyCode: viewModel.currencyCode),
                color: AppColors.income
            )
            if let highest = viewModel.highestExpenseMonth, highest.expense > 0 {
                insightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: L("annual_highest_month"),
                    value: "\(highest.monthLabel) - \(AmountFormatter.format(highest.expense, currencyCode: viewModel.currencyCode))",
                    color: AppColors.warning
                )
            }
            if let lowest = viewModel.lowestExpenseMonth, lowest.expense > 0 {
                insightRow(
                    icon: "chart.line.downtrend.xyaxis",
                    title: L("annual_lowest_month"),
                    value: "\(lowest.monthLabel) - \(AmountFormatter.format(lowest.expense, currencyCode: viewModel.currencyCode))",
                    color: AppColors.success
                )
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func insightRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .fontWeight(.medium)
        }
    }
}
