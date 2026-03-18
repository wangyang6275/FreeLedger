import Foundation
import GRDB

struct TransactionDAO {
    let dbQueue: DatabaseQueue

    func insert(_ transaction: Transaction) throws {
        try dbQueue.write { db in
            try transaction.insert(db)
        }
    }

    func getAll() throws -> [Transaction] {
        try dbQueue.read { db in
            try Transaction
                .order(Transaction.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    func getById(_ id: String) throws -> Transaction? {
        try dbQueue.read { db in
            try Transaction.fetchOne(db, key: id)
        }
    }

    func update(_ transaction: Transaction) throws {
        try dbQueue.write { db in
            try transaction.update(db)
        }
    }

    func delete(id: String) throws {
        try dbQueue.write { db in
            _ = try Transaction.deleteOne(db, key: id)
        }
    }

    func getCategoryBreakdown(year: Int, month: Int, type: String) throws -> [(categoryId: String, total: Int64)] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }
        let startISO = AppDateFormatter.formatISO(startDate)
        let endISO = AppDateFormatter.formatISO(endDate)

        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT category_id, SUM(amount) as total
                FROM transactions
                WHERE type = ? AND created_at >= ? AND created_at < ?
                GROUP BY category_id
                ORDER BY total DESC
                """, arguments: [type, startISO, endISO])
            return rows.map { row in
                let catId: String = row["category_id"]
                let total: Int64 = row["total"]
                return (categoryId: catId, total: total)
            }
        }
    }

    func search(keyword: String?, startDate: String?, endDate: String?, categoryId: String?, limit: Int = 200) throws -> [Transaction] {
        try dbQueue.read { db in
            var sql = """
                SELECT t.* FROM transactions t
                LEFT JOIN categories c ON t.category_id = c.id
                WHERE 1=1
                """
            var args: [DatabaseValueConvertible] = []

            if let keyword = keyword, !keyword.isEmpty {
                sql += " AND (t.note LIKE ? ESCAPE '\\' OR c.name_key LIKE ? ESCAPE '\\')"
                let escaped = keyword
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "%", with: "\\%")
                    .replacingOccurrences(of: "_", with: "\\_")
                let pattern = "%\(escaped)%"
                args.append(pattern)
                args.append(pattern)
            }
            if let startDate = startDate {
                sql += " AND t.created_at >= ?"
                args.append(startDate)
            }
            if let endDate = endDate {
                sql += " AND t.created_at < ?"
                args.append(endDate)
            }
            if let categoryId = categoryId {
                sql += " AND t.category_id = ?"
                args.append(categoryId)
            }
            sql += " ORDER BY t.created_at DESC LIMIT ?"
            args.append(limit)

            return try Transaction.fetchAll(db, sql: sql, arguments: StatementArguments(args))
        }
    }

    func getByMonth(year: Int, month: Int) throws -> [Transaction] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }
        let startISO = AppDateFormatter.formatISO(startDate)
        let endISO = AppDateFormatter.formatISO(endDate)

        return try dbQueue.read { db in
            try Transaction
                .filter(Transaction.Columns.createdAt >= startISO)
                .filter(Transaction.Columns.createdAt < endISO)
                .order(Transaction.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    func getByYear(year: Int) throws -> [Transaction] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return []
        }
        let startISO = AppDateFormatter.formatISO(startDate)
        let endISO = AppDateFormatter.formatISO(endDate)

        return try dbQueue.read { db in
            try Transaction
                .filter(Transaction.Columns.createdAt >= startISO)
                .filter(Transaction.Columns.createdAt < endISO)
                .order(Transaction.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    func getCategoryBreakdownForYear(year: Int, type: String) throws -> [(categoryId: String, total: Int64)] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return []
        }
        let startISO = AppDateFormatter.formatISO(startDate)
        let endISO = AppDateFormatter.formatISO(endDate)

        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT category_id, SUM(amount) as total
                FROM transactions
                WHERE type = ? AND created_at >= ? AND created_at < ?
                GROUP BY category_id
                ORDER BY total DESC
                """, arguments: [type, startISO, endISO])
            return rows.map { row in
                let catId: String = row["category_id"]
                let total: Int64 = row["total"]
                return (categoryId: catId, total: total)
            }
        }
    }

    func getDailySummaries(year: Int, month: Int) throws -> [(day: Int, expense: Int64, income: Int64, count: Int)] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }
        let startISO = AppDateFormatter.formatISO(startDate)
        let endISO = AppDateFormatter.formatISO(endDate)

        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    CAST(substr(created_at, 9, 2) AS INTEGER) as day,
                    SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense,
                    SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
                    COUNT(*) as count
                FROM transactions
                WHERE created_at >= ? AND created_at < ?
                GROUP BY day
                ORDER BY day
                """, arguments: [startISO, endISO])
            return rows.map { row in
                (day: row["day"] as Int,
                 expense: row["expense"] as Int64,
                 income: row["income"] as Int64,
                 count: row["count"] as Int)
            }
        }
    }

    func getByDay(year: Int, month: Int, day: Int) throws -> [Transaction] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: day)),
              let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            return []
        }
        let startISO = AppDateFormatter.formatISO(startDate)
        let endISO = AppDateFormatter.formatISO(endDate)

        return try dbQueue.read { db in
            try Transaction
                .filter(Transaction.Columns.createdAt >= startISO)
                .filter(Transaction.Columns.createdAt < endISO)
                .order(Transaction.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    // MARK: - SQL Aggregation

    func getSummary(startISO: String, endISO: String) throws -> (expense: Int64, income: Int64) {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT type, SUM(amount) as total
                FROM transactions
                WHERE created_at >= ? AND created_at < ?
                GROUP BY type
                """, arguments: [startISO, endISO])
            var expense: Int64 = 0
            var income: Int64 = 0
            for row in rows {
                let type: String = row["type"]
                let total: Int64 = row["total"]
                if type == TransactionType.expense.rawValue {
                    expense = total
                } else {
                    income = total
                }
            }
            return (expense: expense, income: income)
        }
    }

    func getMonthlyTrends(startISO: String, endISO: String) throws -> [(year: Int, month: Int, expense: Int64, income: Int64)] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    CAST(substr(created_at, 1, 4) AS INTEGER) as y,
                    CAST(substr(created_at, 6, 2) AS INTEGER) as m,
                    SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense,
                    SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income
                FROM transactions
                WHERE created_at >= ? AND created_at < ?
                GROUP BY y, m
                ORDER BY y, m
                """, arguments: [startISO, endISO])
            return rows.map { row in
                (year: row["y"] as Int, month: row["m"] as Int,
                 expense: row["expense"] as Int64, income: row["income"] as Int64)
            }
        }
    }
}
