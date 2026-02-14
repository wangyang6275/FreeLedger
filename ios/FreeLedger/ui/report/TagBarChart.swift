import SwiftUI
import Charts

struct TagBarChart: View {
    let tagBreakdown: [TagExpenseBreakdown]
    let currencyCode: String

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
        Text(L("report_tag_chart_title"))
            .font(AppTypography.title2)
            .foregroundColor(AppColors.textPrimary)
    }

    private var chartView: some View {
        Chart(tagBreakdown) { item in
            BarMark(
                x: .value("Amount", Double(item.total) / 100.0),
                y: .value("Tag", item.tagName)
            )
            .foregroundStyle(Color(hex: item.colorHex))
            .annotation(position: .trailing) {
                Text(AmountFormatter.format(item.total, currencyCode: currencyCode))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
            }
        }
        .frame(height: CGFloat(max(tagBreakdown.count, 1)) * 44)
    }
}
