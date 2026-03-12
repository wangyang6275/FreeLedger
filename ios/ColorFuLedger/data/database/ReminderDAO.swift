import Foundation
import GRDB

struct ReminderDAO {
    let dbQueue: DatabaseQueue

    func getAll() throws -> [Reminder] {
        try dbQueue.read { db in
            try Reminder.order(Column("created_at").desc).fetchAll(db)
        }
    }

    func getEnabled() throws -> [Reminder] {
        try dbQueue.read { db in
            try Reminder.filter(Column("is_enabled") == true)
                .order(Column("created_at").desc)
                .fetchAll(db)
        }
    }

    func getById(_ id: String) throws -> Reminder? {
        try dbQueue.read { db in
            try Reminder.fetchOne(db, key: id)
        }
    }

    func insert(_ reminder: Reminder) throws {
        try dbQueue.write { db in
            try reminder.insert(db)
        }
    }

    func update(_ reminder: Reminder) throws {
        try dbQueue.write { db in
            try reminder.update(db)
        }
    }

    func delete(id: String) throws {
        try dbQueue.write { db in
            _ = try Reminder.deleteOne(db, key: id)
        }
    }
}
