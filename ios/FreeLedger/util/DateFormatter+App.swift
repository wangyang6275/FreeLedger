import Foundation

enum AppDateFormatter {
    nonisolated(unsafe) private static let isoParser = ISO8601DateFormatter()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let monthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f
    }()

    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月"
        return f
    }()

    static func parseISO(_ isoString: String) -> Date? {
        isoParser.date(from: isoString)
    }

    static func formatTime(_ isoString: String) -> String {
        guard let date = parseISO(isoString) else { return "" }
        return timeFormatter.string(from: date)
    }

    static func formatGroupTitle(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "date_today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "date_yesterday")
        } else {
            return monthDayFormatter.string(from: date)
        }
    }

    static func formatMonthTitle(_ date: Date = Date()) -> String {
        monthTitleFormatter.string(from: date)
    }

    static func groupTransactionsByDate(_ transactions: [Transaction]) -> [(String, [Transaction])] {
        let calendar = Calendar.current
        var groups: [(key: String, date: Date, transactions: [Transaction])] = []
        var currentKey: String?
        var currentDate: Date?
        var currentGroup: [Transaction] = []

        for tx in transactions {
            guard let date = parseISO(tx.createdAt) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let key = formatGroupTitle(dayStart)

            if key == currentKey {
                currentGroup.append(tx)
            } else {
                if let ck = currentKey, let cd = currentDate {
                    groups.append((key: ck, date: cd, transactions: currentGroup))
                }
                currentKey = key
                currentDate = dayStart
                currentGroup = [tx]
            }
        }

        if let ck = currentKey, let cd = currentDate {
            groups.append((key: ck, date: cd, transactions: currentGroup))
        }

        return groups.map { ($0.key, $0.transactions) }
    }
}
