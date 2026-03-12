import Foundation
import GRDB

struct SettingsDAO {
    let dbQueue: DatabaseQueue

    func get(key: String) throws -> String? {
        try dbQueue.read { db in
            try Setting.fetchOne(db, key: key)?.value
        }
    }

    func set(key: String, value: String) throws {
        try dbQueue.write { db in
            let setting = Setting(key: key, value: value)
            try setting.save(db)
        }
    }
}
