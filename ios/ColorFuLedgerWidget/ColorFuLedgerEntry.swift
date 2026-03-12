import WidgetKit

struct ColorFuLedgerEntry: TimelineEntry {
    let date: Date
    let totalExpense: Int64
    let totalIncome: Int64
    let balance: Int64
    let monthTitle: String
    let currencyCode: String
    let recentTransactions: [WidgetTransactionItem]

    static var placeholder: ColorFuLedgerEntry {
        ColorFuLedgerEntry(
            date: Date(),
            totalExpense: 250000,
            totalIncome: 800000,
            balance: 550000,
            monthTitle: "2月",
            currencyCode: "CNY",
            recentTransactions: []
        )
    }

    static var empty: ColorFuLedgerEntry {
        ColorFuLedgerEntry(
            date: Date(),
            totalExpense: 0,
            totalIncome: 0,
            balance: 0,
            monthTitle: "",
            currencyCode: "CNY",
            recentTransactions: []
        )
    }
}
