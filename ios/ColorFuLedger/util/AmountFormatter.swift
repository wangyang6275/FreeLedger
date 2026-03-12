import Foundation

enum AmountFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static func format(_ cents: Int64, locale: Locale = .current, currencyCode: String? = nil) -> String {
        let value = Double(cents) / 100.0
        guard let f = formatter.copy() as? NumberFormatter else { return "¥0.00" }
        f.locale = locale
        if let code = currencyCode {
            f.currencyCode = code
        }
        return f.string(from: NSNumber(value: value)) ?? "¥0.00"
    }

    static func formatDisplay(_ amountString: String, currencySymbol: String = "¥") -> String {
        if amountString.isEmpty {
            return "\(currencySymbol) 0.00"
        }
        return "\(currencySymbol) \(amountString)"
    }

    static func toCents(_ amountString: String) -> Int64 {
        guard let value = Double(amountString) else { return 0 }
        return Int64(round(value * 100))
    }
}
