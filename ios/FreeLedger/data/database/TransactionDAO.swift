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
        let formatter = ISO8601DateFormatter()
        let startISO = formatter.string(from: startDate)
        let endISO = formatter.string(from: endDate)

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

    func search(keyword: String?, startDate: String?, endDate: String?, categoryId: String?) throws -> [Transaction] {
        try dbQueue.read { db in
            var sql = """
                SELECT t.* FROM transactions t
                LEFT JOIN categories c ON t.category_id = c.id
                WHERE 1=1
                """
            var args: [DatabaseValueConvertible] = []

            if let keyword = keyword, !keyword.isEmpty {
                sql += " AND (t.note LIKE ? OR c.name_key LIKE ?)"
                let pattern = "%\(keyword)%"
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
            sql += " ORDER BY t.created_at DESC"

            return try Transaction.fetchAll(db, sql: sql, arguments: StatementArguments(args))
        }
    }

    func getByMonth(year: Int, month: Int) throws -> [Transaction] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }
        let formatter = ISO8601DateFormatter()
        let startISO = formatter.string(from: startDate)
        let endISO = formatter.string(from: endDate)

        return try dbQueue.read { db in
            try Transaction
                .filter(Transaction.Columns.createdAt >= startISO)
                .filter(Transaction.Columns.createdAt < endISO)
                .order(Transaction.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }
}
