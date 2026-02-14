import SwiftUI

struct ReportView: View {
    @State private var viewModel: ReportViewModel

    init(transactionRepository: TransactionRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol) {
        _viewModel = State(initialValue: ReportViewModel(
            transactionRepository: transactionRepository,
            settingsRepository: settingsRepository,
            tagRepository: tagRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    monthSelector
                    summarySection

                    if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        pieChartSection
                        trendChartSection
                        if !viewModel.tagBreakdown.isEmpty {
                            tagBarChartSection
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .navigationTitle(String(localized: "tab_reports"))
            .onAppear { viewModel.loadData() }
            .alert(String(localized: "error_title"), isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(String(localized: "error_ok"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button(action: { viewModel.previousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(String(localized: "a11y_previous_month"))

            Spacer()

            Text(viewModel.monthTitle)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button(action: { viewModel.nextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(String(localized: "a11y_next_month"))
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        HStack(spacing: 0) {
            summaryItem(
                title: String(localized: "report_expense_label"),
                amount: viewModel.summary.totalExpense,
                color: AppColors.expense
            )
            summaryItem(
                title: String(localized: "report_income_label"),
                amount: viewModel.summary.totalIncome,
                color: AppColors.income
            )
            summaryItem(
                title: String(localized: "report_balance_label"),
                amount: viewModel.summary.totalIncome - viewModel.summary.totalExpense,
                color: AppColors.textPrimary
            )
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func summaryItem(title: String, amount: Int64, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(AmountFormatter.format(amount, currencyCode: viewModel.currencyCode))
                .font(AppTypography.body)
                .foregroundColor(color)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pie Chart

    private var pieChartSection: some View {
        PieChartView(
            breakdown: viewModel.expenseBreakdown,
            totalExpense: viewModel.summary.totalExpense,
            currencyCode: viewModel.currencyCode,
            selectedCategoryId: viewModel.selectedCategoryId,
            onSelect: { viewModel.selectCategory($0) }
        )
    }

    // MARK: - Tag Bar Chart

    private var tagBarChartSection: some View {
        TagBarChart(
            tagBreakdown: viewModel.tagBreakdown,
            currencyCode: viewModel.currencyCode
        )
    }

    // MARK: - Trend Chart

    private var trendChartSection: some View {
        TrendLineChart(
            trendData: viewModel.trendData,
            currencyCode: viewModel.currencyCode
        )
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)

            Text(String(localized: "report_empty_state"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.top, AppSpacing.xl)
    }
}
