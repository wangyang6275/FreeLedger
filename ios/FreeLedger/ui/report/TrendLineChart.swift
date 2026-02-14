import SwiftUI
import Charts

struct TrendChartEntry: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
    let type: String
}

struct TrendLineChart: View {
    let trendData: [MonthlyTrend]
    let currencyCode: String

    private var chartEntries: [TrendChartEntry] {
        let expenseLabel = String(localized: "report_expense_label")
        let incomeLabel = String(localized: "report_income_label")
        var entries: [TrendChartEntry] = []
        for item in trendData {
            entries.append(TrendChartEntry(month: item.monthLabel, amount: Double(item.expense) / 100.0, type: expenseLabel))
            entries.append(TrendChartEntry(month: item.monthLabel, amount: Double(item.income) / 100.0, type: incomeLabel))
        }
        return entries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            chartTitle
            chartView
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var chartTitle: some View {
        Text(String(localized: "report_trend_title"))
            .font(AppTypography.title2)
            .foregroundColor(AppColors.textPrimary)
    }

    private var chartView: some View {
        Chart(chartEntries) { entry in
            LineMark(
                x: .value("Month", entry.month),
                y: .value("Amount", entry.amount)
            )
            .foregroundStyle(by: .value("Type", entry.type))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Month", entry.month),
                y: .value("Amount", entry.amount)
            )
            .foregroundStyle(by: .value("Type", entry.type))
        }
        .chartForegroundStyleScale([
            String(localized: "report_expense_label"): AppColors.expense,
            String(localized: "report_income_label"): AppColors.income
        ])
        .chartLegend(position: .bottom, spacing: AppSpacing.sm)
        .frame(height: 200)
    }
}
