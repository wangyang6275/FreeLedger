import Foundation
import GRDB

struct TagDAO {
    let dbQueue: DatabaseQueue

    func getAll() throws -> [Tag] {
        try dbQueue.read { db in
            try Tag.order(Column("created_at").desc).fetchAll(db)
        }
    }

    func getById(_ id: String) throws -> Tag? {
        try dbQueue.read { db in
            try Tag.fetchOne(db, key: id)
        }
    }

    func insert(_ tag: Tag) throws {
        try dbQueue.write { db in
            try tag.insert(db)
        }
    }

    func update(_ tag: Tag) throws {
        try dbQueue.write { db in
            try tag.update(db)
        }
    }

    func delete(id: String) throws {
        try dbQueue.write { db in
            _ = try Tag.deleteOne(db, key: id)
        }
    }

    func getTransactionCountPerTag() throws -> [String: Int] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT tag_id, COUNT(*) as cnt FROM transaction_tags GROUP BY tag_id
                """)
            var result: [String: Int] = [:]
            for row in rows {
                let tagId: String = row["tag_id"]
                let count: Int = row["cnt"]
                result[tagId] = count
            }
            return result
        }
    }

    func getTransactionsForTag(tagId: String) throws -> [Transaction] {
        try dbQueue.read { db in
            try Transaction.fetchAll(db, sql: """
                SELECT t.* FROM transactions t
                INNER JOIN transaction_tags tt ON t.id = tt.transaction_id
                WHERE tt.tag_id = ?
                ORDER BY t.created_at DESC
                """, arguments: [tagId])
        }
    }

    func getTagsForTransaction(transactionId: String) throws -> [Tag] {
        try dbQueue.read { db in
            try Tag.fetchAll(db, sql: """
                SELECT t.* FROM tags t
                INNER JOIN transaction_tags tt ON t.id = tt.tag_id
                WHERE tt.transaction_id = ?
                ORDER BY t.created_at DESC
                """, arguments: [transactionId])
        }
    }

    func getTagExpenseBreakdown(year: Int, month: Int) throws -> [TagExpenseBreakdown] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }
        let startISO = AppDateFormatter.formatISO(startDate)
        let endISO = AppDateFormatter.formatISO(endDate)

        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT tg.id as tag_id, tg.name, tg.color_hex, SUM(tx.amount) as total
                FROM tags tg
                INNER JOIN transaction_tags tt ON tg.id = tt.tag_id
                INNER JOIN transactions tx ON tt.transaction_id = tx.id
                WHERE tx.type = 'expense' AND tx.created_at >= ? AND tx.created_at < ?
                GROUP BY tg.id
                ORDER BY total DESC
                """, arguments: [startISO, endISO])
            return rows.map { row in
                TagExpenseBreakdown(
                    tagId: row["tag_id"],
                    tagName: row["name"],
                    colorHex: row["color_hex"],
                    total: row["total"]
                )
            }
        }
    }

    func setTagsForTransaction(transactionId: String, tagIds: [String], in db: Database) throws {
        try db.execute(
            sql: "DELETE FROM transaction_tags WHERE transaction_id = ?",
            arguments: [transactionId]
        )
        for tagId in tagIds {
            let link = TransactionTag(transactionId: transactionId, tagId: tagId)
            try link.insert(db)
        }
    }
}
