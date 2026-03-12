import Foundation
import GRDB

struct BackupService {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func exportBackup() throws -> Data {
        let backup = try dbQueue.read { db in
            let transactions = try Transaction.order(Column("created_at").desc).fetchAll(db)
            let categories = try Category.fetchAll(db)
            let tags = try Tag.fetchAll(db)
            let transactionTags = try TransactionTag.fetchAll(db)

            let checksum = BackupData.generateChecksum(
                transactions: transactions,
                categories: categories,
                tags: tags,
                transactionTags: transactionTags
            )

            return BackupData(
                version: 1,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                checksum: checksum,
                transactions: transactions,
                categories: categories,
                tags: tags,
                transactionTags: transactionTags
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    func importBackup(data: Data) throws -> Int {
        let decoder = JSONDecoder()
        let backup: BackupData
        do {
            backup = try decoder.decode(BackupData.self, from: data)
        } catch {
            throw BackupError.invalidFile
        }

        let expectedChecksum = BackupData.generateChecksum(
            transactions: backup.transactions,
            categories: backup.categories,
            tags: backup.tags,
            transactionTags: backup.transactionTags
        )

        guard backup.checksum == expectedChecksum else {
            throw BackupError.checksumMismatch
        }

        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM transaction_tags")
            try db.execute(sql: "DELETE FROM transactions")
            try db.execute(sql: "DELETE FROM tags")
            try db.execute(sql: "DELETE FROM categories")

            for category in backup.categories {
                try category.insert(db)
            }
            for transaction in backup.transactions {
                try transaction.insert(db)
            }
            for tag in backup.tags {
                try tag.insert(db)
            }
            for tt in backup.transactionTags {
                try tt.insert(db)
            }
        }

        return backup.transactions.count
    }

    var transactionCount: Int {
        (try? dbQueue.read { db in
            try Transaction.fetchCount(db)
        }) ?? 0
    }
}

enum BackupError: Error {
    case invalidFile
    case checksumMismatch
}
