import Foundation
import GRDB

protocol TransactionRepositoryProtocol {
    func insert(amount: Int64, type: String, categoryId: String, note: String?, tagIds: [String]) throws
    func getAll() throws -> [Transaction]
    func getById(_ id: String) throws -> Transaction?
    func update(_ transaction: Transaction) throws
    func delete(id: String) throws
    func getTransactionsForMonth(year: Int, month: Int) throws -> [Transaction]
    func getMonthlySummary(year: Int, month: Int) throws -> TransactionSummary
    func getTagsForTransaction(transactionId: String) throws -> [Tag]
    func setTagsForTransaction(transactionId: String, tagIds: [String]) throws
    func getCategoryBreakdown(year: Int, month: Int, type: String) throws -> [CategoryBreakdown]
    func getLast6MonthsSummary(fromYear: Int, fromMonth: Int) throws -> [MonthlyTrend]
    func search(keyword: String?, startDate: String?, endDate: String?, categoryId: String?, limit: Int) throws -> [Transaction]
    func getAnnualSummary(year: Int) throws -> TransactionSummary
    func getAnnualMonthlySummaries(year: Int) throws -> [MonthlyTrend]
    func getAnnualCategoryBreakdown(year: Int, type: String) throws -> [CategoryBreakdown]
}

final class TransactionRepository: TransactionRepositoryProtocol {
    private let dbQueue: DatabaseQueue
    private let transactionDAO: TransactionDAO
    private let categoryDAO: CategoryDAO
    private let tagDAO: TagDAO

    init(dbQueue: DatabaseQueue, transactionDAO: TransactionDAO, categoryDAO: CategoryDAO, tagDAO: TagDAO) {
        self.dbQueue = dbQueue
        self.transactionDAO = transactionDAO
        self.categoryDAO = categoryDAO
        self.tagDAO = tagDAO
    }

    func insert(amount: Int64, type: String, categoryId: String, note: String?, tagIds: [String] = []) throws {
        try dbQueue.write { db in
            let transaction = Transaction(
                amount: amount,
                type: type,
                categoryId: categoryId,
                note: note
            )
            try transaction.insert(db)
            try db.execute(
                sql: "UPDATE categories SET usage_count = usage_count + 1 WHERE id = ?",
                arguments: [categoryId]
            )
            if !tagIds.isEmpty {
                try tagDAO.setTagsForTransaction(transactionId: transaction.id, tagIds: tagIds, in: db)
            }
        }
    }

    func getAll() throws -> [Transaction] {
        try transactionDAO.getAll()
    }

    func getById(_ id: String) throws -> Transaction? {
        try transactionDAO.getById(id)
    }

    func update(_ transaction: Transaction) throws {
        try transactionDAO.update(transaction)
    }

    func delete(id: String) throws {
        try transactionDAO.delete(id: id)
    }

    func getTransactionsForMonth(year: Int, month: Int) throws -> [Transaction] {
        try transactionDAO.getByMonth(year: year, month: month)
    }

    func getMonthlySummary(year: Int, month: Int) throws -> TransactionSummary {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return .empty
        }
        return try getSummary(from: startDate, to: endDate)
    }

    func getTagsForTransaction(transactionId: String) throws -> [Tag] {
        try tagDAO.getTagsForTransaction(transactionId: transactionId)
    }

    func setTagsForTransaction(transactionId: String, tagIds: [String]) throws {
        try dbQueue.write { db in
            try tagDAO.setTagsForTransaction(transactionId: transactionId, tagIds: tagIds, in: db)
        }
    }

    func search(keyword: String?, startDate: String?, endDate: String?, categoryId: String?, limit: Int = 200) throws -> [Transaction] {
        try transactionDAO.search(keyword: keyword, startDate: startDate, endDate: endDate, categoryId: categoryId, limit: limit)
    }

    func getLast6MonthsSummary(fromYear: Int, fromMonth: Int) throws -> [MonthlyTrend] {
        let monthFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = LanguageManager.locale
            f.setLocalizedDateFormatFromTemplate("MMMM")
            return f
        }()

        let calendar = Calendar.current
        var startY = fromYear
        var startM = fromMonth
        for _ in 0..<5 {
            startM -= 1
            if startM < 1 { startM = 12; startY -= 1 }
        }

        guard let startDate = calendar.date(from: DateComponents(year: startY, month: startM, day: 1)),
              let rawEnd = calendar.date(from: DateComponents(year: fromYear, month: fromMonth, day: 1)),
              let endDate = calendar.date(byAdding: .month, value: 1, to: rawEnd) else {
            return []
        }

        let dbData = try transactionDAO.getMonthlyTrends(
            startISO: AppDateFormatter.formatISO(startDate),
            endISO: AppDateFormatter.formatISO(endDate)
        )
        let lookup = Dictionary(uniqueKeysWithValues: dbData.map { ("\($0.year)-\($0.month)", $0) })

        var results: [MonthlyTrend] = []
        var y = startY
        var m = startM
        for _ in 0..<6 {
            let key = "\(y)-\(m)"
            let expense = lookup[key]?.expense ?? 0
            let income = lookup[key]?.income ?? 0
            var comps = DateComponents()
            comps.year = y; comps.month = m; comps.day = 1
            let label = calendar.date(from: comps).map { monthFormatter.string(from: $0) } ?? "\(m)"
            results.append(MonthlyTrend(year: y, month: m, monthLabel: label, expense: expense, income: income))
            m += 1
            if m > 12 { m = 1; y += 1 }
        }
        return results
    }

    func getCategoryBreakdown(year: Int, month: Int, type: String) throws -> [CategoryBreakdown] {
        let rawData = try transactionDAO.getCategoryBreakdown(year: year, month: month, type: type)
        let grandTotal = rawData.reduce(0 as Int64) { $0 + $1.total }
        let categoryDict = try categoryDAO.getAllAsDict()

        return rawData.map { item in
            let cat = categoryDict[item.categoryId]
            let pct = grandTotal > 0 ? Double(item.total) / Double(grandTotal) * 100.0 : 0
            let name: String
            if let c = cat {
                if c.isCustom {
                    name = c.nameKey
                } else {
                    name = L(c.nameKey)
                }
            } else {
                name = "—"
            }
            return CategoryBreakdown(
                categoryId: item.categoryId,
                categoryName: name,
                iconName: cat?.iconName ?? "",
                colorHex: cat?.colorHex ?? "#E0E0E0",
                total: item.total,
                percentage: pct
            )
        }
    }

    func getAnnualSummary(year: Int) throws -> TransactionSummary {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return .empty
        }
        return try getSummary(from: startDate, to: endDate)
    }

    private func getSummary(from startDate: Date, to endDate: Date) throws -> TransactionSummary {
        let result = try transactionDAO.getSummary(
            startISO: AppDateFormatter.formatISO(startDate),
            endISO: AppDateFormatter.formatISO(endDate)
        )
        return TransactionSummary(totalExpense: result.expense, totalIncome: result.income)
    }

    func getAnnualMonthlySummaries(year: Int) throws -> [MonthlyTrend] {
        let monthFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = LanguageManager.locale
            f.setLocalizedDateFormatFromTemplate("MMM")
            return f
        }()

        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return []
        }

        let dbData = try transactionDAO.getMonthlyTrends(
            startISO: AppDateFormatter.formatISO(startDate),
            endISO: AppDateFormatter.formatISO(endDate)
        )
        let lookup = Dictionary(uniqueKeysWithValues: dbData.map { ("\($0.year)-\($0.month)", $0) })

        var results: [MonthlyTrend] = []
        for m in 1...12 {
            let key = "\(year)-\(m)"
            let expense = lookup[key]?.expense ?? 0
            let income = lookup[key]?.income ?? 0
            var comps = DateComponents()
            comps.year = year; comps.month = m; comps.day = 1
            let label = calendar.date(from: comps).map { monthFormatter.string(from: $0) } ?? "\(m)"
            results.append(MonthlyTrend(year: year, month: m, monthLabel: label, expense: expense, income: income))
        }
        return results
    }

    func getAnnualCategoryBreakdown(year: Int, type: String) throws -> [CategoryBreakdown] {
        let rawData = try transactionDAO.getCategoryBreakdownForYear(year: year, type: type)
        let grandTotal = rawData.reduce(0 as Int64) { $0 + $1.total }
        let categoryDict = try categoryDAO.getAllAsDict()

        return rawData.map { item in
            let cat = categoryDict[item.categoryId]
            let pct = grandTotal > 0 ? Double(item.total) / Double(grandTotal) * 100.0 : 0
            let name: String
            if let c = cat {
                name = c.isCustom ? c.nameKey : L(c.nameKey)
            } else {
                name = "—"
            }
            return CategoryBreakdown(
                categoryId: item.categoryId,
                categoryName: name,
                iconName: cat?.iconName ?? "",
                colorHex: cat?.colorHex ?? "#E0E0E0",
                total: item.total,
                percentage: pct
            )
        }
    }
}
