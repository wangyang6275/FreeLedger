import Foundation
import WidgetKit

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
    static let appGroupId = "group.com.colorfuledger.app"
    private static let fileName = "widget_data.json"

    private static var sharedFileURL: URL? {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            return containerURL.appendingPathComponent(fileName)
        }
        #if targetEnvironment(simulator)
        return URL(fileURLWithPath: "/private/tmp/\(fileName)")
        #else
        return nil
        #endif
    }

    static func write(_ data: WidgetData) {
        guard let url = sharedFileURL else { return }
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Widget data write failed: \(error.localizedDescription)")
        }
    }

    static func read() -> WidgetData? {
        guard let url = sharedFileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(WidgetData.self, from: data)
        } catch {
            return nil
        }
    }
}
