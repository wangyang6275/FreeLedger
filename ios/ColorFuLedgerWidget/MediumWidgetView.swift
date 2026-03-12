import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: ColorFuLedgerEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left: Summary
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                    Text(entry.monthTitle.isEmpty ? monthFallback : entry.monthTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "widget_expense"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(WidgetAmountFormatter.formatCompact(entry.totalExpense, currencyCode: entry.currencyCode))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(localized: "widget_income"))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(WidgetAmountFormatter.formatCompact(entry.totalIncome, currencyCode: entry.currencyCode))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(localized: "widget_balance"))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(WidgetAmountFormatter.formatCompact(entry.balance, currencyCode: entry.currencyCode))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(entry.balance >= 0 ? .blue : .red)
                            .lineLimit(1)
                    }
                }

                // Quick record button
                Link(destination: URL(string: "freeledger://record")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text(String(localized: "widget_quick_record"))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.gradient)
                    .clipShape(Capsule())
                }
                .padding(.top, 2)
            }

            Divider()

            // Right: Recent transactions
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "widget_recent"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)

                if entry.recentTransactions.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(String(localized: "widget_no_records"))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(spacing: 6) {
                        ForEach(Array(entry.recentTransactions.prefix(4).enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 6) {
                                Image(systemName: item.categoryIcon)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: item.categoryColor))
                                    .frame(width: 16)

                                Text(item.categoryName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Spacer()

                                Text(formatAmount(item))
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(item.isExpense ? .primary : .green)
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer()
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

    private func formatAmount(_ item: WidgetTransactionItem) -> String {
        let prefix = item.isExpense ? "-" : "+"
        return prefix + WidgetAmountFormatter.formatCompact(item.amount, currencyCode: entry.currencyCode)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
