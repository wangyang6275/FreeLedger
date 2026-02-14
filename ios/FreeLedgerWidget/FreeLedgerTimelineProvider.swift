import WidgetKit

struct FreeLedgerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FreeLedgerEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FreeLedgerEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FreeLedgerEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> FreeLedgerEntry {
        guard let data = WidgetDataBridge.read() else {
            return .empty
        }
        return FreeLedgerEntry(
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
