import Foundation

enum WidgetAmountFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static func format(_ amount: Int64, currencyCode: String) -> String {
        let value = Double(amount) / 100.0
        let symbol = currencySymbol(currencyCode)
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0.00"
        return "\(symbol)\(formatted)"
    }

    static func formatCompact(_ amount: Int64, currencyCode: String) -> String {
        let value = Double(amount) / 100.0
        let symbol = currencySymbol(currencyCode)
        if value >= 10000 {
            let wan = value / 10000
            return String(format: "%@%.1fw", symbol, wan)
        }
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0.00"
        return "\(symbol)\(formatted)"
    }

    private static func currencySymbol(_ code: String) -> String {
        switch code {
        case "CNY", "JPY": return "¥"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "KRW": return "₩"
        case "HKD": return "HK$"
        case "TWD": return "NT$"
        default: return code
        }
    }
}
