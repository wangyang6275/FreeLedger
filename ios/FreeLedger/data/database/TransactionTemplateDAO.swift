import Foundation
import GRDB

struct TransactionTemplateDAO {
    let dbQueue: DatabaseQueue

    func getAll() throws -> [TransactionTemplate] {
        try dbQueue.read { db in
            try TransactionTemplate
                .order(TransactionTemplate.Columns.sortOrder.asc)
                .order(TransactionTemplate.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    func getById(_ id: String) throws -> TransactionTemplate? {
        try dbQueue.read { db in
            try TransactionTemplate.fetchOne(db, key: id)
        }
    }

    func insert(_ template: TransactionTemplate) throws {
        try dbQueue.write { db in
            try template.insert(db)
        }
    }

    func update(_ template: TransactionTemplate) throws {
        try dbQueue.write { db in
            try template.update(db)
        }
    }

    func delete(id: String) throws {
        try dbQueue.write { db in
            _ = try TransactionTemplate.deleteOne(db, key: id)
        }
    }
}
