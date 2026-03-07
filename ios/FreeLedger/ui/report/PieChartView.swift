import SwiftUI
import Charts

struct PieChartView: View {
    let breakdown: [CategoryBreakdown]
    let totalExpense: Int64
    let currencyCode: String
    let selectedCategoryId: String?
    let onSelect: (String?) -> Void

    @State private var rawSelection: Double?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            chartSection
            legendSection
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        ZStack {
            Chart(breakdown) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(Color(hex: item.colorHex))
                .opacity(selectedCategoryId == nil || selectedCategoryId == item.categoryId ? 1.0 : 0.4)
            }
            .chartAngleSelection(value: $rawSelection)
            .frame(height: 220)

            centerLabel
        }
        .onChange(of: rawSelection) { _, newValue in
            guard let newValue else {
                onSelect(nil)
                return
            }
            var cumulative: Double = 0
            for item in breakdown {
                cumulative += Double(item.total)
                if newValue <= cumulative {
                    onSelect(item.categoryId)
                    return
                }
            }
            onSelect(nil)
        }
    }

    private var centerLabel: some View {
        VStack(spacing: 2) {
            if let selId = selectedCategoryId,
               let item = breakdown.first(where: { $0.categoryId == selId }) {
                Text(item.categoryName)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(AmountFormatter.format(item.total, currencyCode: currencyCode))
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.bold)
                Text(String(format: "%.1f%%", item.percentage))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            } else {
                Text(L("report_total_expense"))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(AmountFormatter.format(totalExpense, currencyCode: currencyCode))
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.bold)
            }
        }
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(spacing: 0) {
            ForEach(breakdown) { item in
                legendRow(item)
                if item.id != breakdown.last?.id {
                    Divider().padding(.leading, AppSpacing.xl)
                }
            }
        }
        .glassCard()
    }

    private func legendRow(_ item: CategoryBreakdown) -> some View {
        Button(action: { onSelect(item.categoryId) }) {
            HStack(spacing: AppSpacing.md) {
                CategoryIconView(
                    iconName: item.iconName,
                    colorHex: item.colorHex,
                    size: 36,
                    iconSize: 18
                )

                Text(item.categoryName)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(AmountFormatter.format(item.total, currencyCode: currencyCode))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Text(String(format: "%.1f%%", item.percentage))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .background(
                selectedCategoryId == item.categoryId
                    ? Color(hex: item.colorHex).opacity(0.1)
                    : Color.clear
            )
        }
    }
}
