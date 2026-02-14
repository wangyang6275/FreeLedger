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
    func search(keyword: String?, startDate: String?, endDate: String?, categoryId: String?) throws -> [Transaction]
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
        let transactions = try getTransactionsForMonth(year: year, month: month)
        var totalExpense: Int64 = 0
        var totalIncome: Int64 = 0
        for tx in transactions {
            if tx.type == TransactionType.expense.rawValue {
                totalExpense += tx.amount
            } else {
                totalIncome += tx.amount
            }
        }
        return TransactionSummary(totalExpense: totalExpense, totalIncome: totalIncome)
    }

    func getTagsForTransaction(transactionId: String) throws -> [Tag] {
        try tagDAO.getTagsForTransaction(transactionId: transactionId)
    }

    func setTagsForTransaction(transactionId: String, tagIds: [String]) throws {
        try dbQueue.write { db in
            try tagDAO.setTagsForTransaction(transactionId: transactionId, tagIds: tagIds, in: db)
        }
    }

    func search(keyword: String?, startDate: String?, endDate: String?, categoryId: String?) throws -> [Transaction] {
        try transactionDAO.search(keyword: keyword, startDate: startDate, endDate: endDate, categoryId: categoryId)
    }

    func getLast6MonthsSummary(fromYear: Int, fromMonth: Int) throws -> [MonthlyTrend] {
        let monthFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = LanguageManager.locale
            f.setLocalizedDateFormatFromTemplate("MMMM")
            return f
        }()

        var results: [MonthlyTrend] = []
        var y = fromYear
        var m = fromMonth

        // Go back 5 months to get 6 months total (including current)
        for _ in 0..<5 {
            m -= 1
            if m < 1 { m = 12; y -= 1 }
        }

        for _ in 0..<6 {
            let summary = try getMonthlySummary(year: y, month: m)
            var comps = DateComponents()
            comps.year = y
            comps.month = m
            comps.day = 1
            let label = Calendar.current.date(from: comps).map { monthFormatter.string(from: $0) } ?? "\(m)"
            results.append(MonthlyTrend(
                year: y, month: m, monthLabel: label,
                expense: summary.totalExpense, income: summary.totalIncome
            ))
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
}
