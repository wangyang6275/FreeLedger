import WidgetKit

struct ColorFuLedgerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ColorFuLedgerEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ColorFuLedgerEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ColorFuLedgerEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> ColorFuLedgerEntry {
        guard let data = WidgetDataBridge.read() else {
            return .empty
        }
        return ColorFuLedgerEntry(
            date: Date(),
            totalExpense: data.totalExpense,
            totalIncome: data.totalIncome,
            balance: data.balance,
            monthTitle: data.monthTitle,
            currencyCode: data.currencyCode,
            recentTransactions: data.recentTransactions
        )
    }
}
