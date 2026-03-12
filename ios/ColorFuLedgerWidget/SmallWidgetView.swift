import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: ColorFuLedgerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                Text(entry.monthTitle.isEmpty ? monthFallback : entry.monthTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "widget_expense"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(WidgetAmountFormatter.formatCompact(entry.totalExpense, currencyCode: entry.currencyCode))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "widget_income"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(WidgetAmountFormatter.formatCompact(entry.totalIncome, currencyCode: entry.currencyCode))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                        .lineLimit(1)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "widget_balance"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(WidgetAmountFormatter.formatCompact(entry.balance, currencyCode: entry.currencyCode))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(entry.balance >= 0 ? .blue : .red)
                        .lineLimit(1)
                }
            }
        }
        .padding(2)
    }

    private var monthFallback: String {
        let f = DateFormatter()
        f.dateFormat = "M月"
        return f.string(from: Date())
    }
}
