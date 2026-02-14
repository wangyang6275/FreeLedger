import Foundation

struct WidgetTransactionItem: Codable {
    let categoryName: String
    let categoryIcon: String
    let categoryColor: String
    let amount: Int64
    let isExpense: Bool
    let note: String?
    let time: String
}

struct WidgetData: Codable {
    let totalExpense: Int64
    let totalIncome: Int64
    let balance: Int64
    let monthTitle: String
    let currencyCode: String
    let recentTransactions: [WidgetTransactionItem]
    let updatedAt: Date
}

enum WidgetDataBridge {
    static let appGroupId = "group.com.freeledger.app"
    static let widgetDataKey = "widget_data"

    static func write(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: widgetDataKey)
        }
    }

    static func read() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }
}
