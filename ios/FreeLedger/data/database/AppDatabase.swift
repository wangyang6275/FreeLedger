import Foundation
import GRDB

final class AppDatabase: Sendable {
    static let shared = AppDatabase()

    let dbQueue: DatabaseQueue

    private init() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbURL = appSupportURL.appendingPathComponent("freeledger.sqlite")
            dbQueue = try DatabaseQueue(path: dbURL.path)
            try migrate()
        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrate()
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "categories") { t in
                t.column("id", .text).primaryKey()
                t.column("name_key", .text).notNull()
                t.column("icon_name", .text).notNull()
                t.column("color_hex", .text).notNull()
                t.column("type", .text).notNull()
                t.column("sort_order", .integer).notNull().defaults(to: 0)
                t.column("usage_count", .integer).notNull().defaults(to: 0)
                t.column("is_custom", .boolean).notNull().defaults(to: false)
                t.column("is_active", .boolean).notNull().defaults(to: true)
            }

            try db.create(table: "transactions") { t in
                t.column("id", .text).primaryKey()
                t.column("amount", .integer).notNull()
                t.column("type", .text).notNull()
                t.column("category_id", .text).notNull()
                    .references("categories", onDelete: .restrict)
                t.column("note", .text)
                t.column("created_at", .text).notNull()
                t.column("updated_at", .text).notNull()
            }

            try db.create(table: "settings") { t in
                t.column("key", .text).primaryKey()
                t.column("value", .text).notNull()
            }

            try db.create(table: "schema_version") { t in
                t.column("version", .integer).notNull()
                t.column("migrated_at", .text).notNull()
            }

            try db.create(
                index: "idx_transactions_created_at",
                on: "transactions",
                columns: ["created_at"]
            )
            try db.create(
                index: "idx_transactions_category_id",
                on: "transactions",
                columns: ["category_id"]
            )
            try db.create(
                index: "idx_transactions_type_created_at",
                on: "transactions",
                columns: ["type", "created_at"]
            )
            try db.create(
                index: "idx_categories_type_usage",
                on: "categories",
                columns: ["type", "usage_count"]
            )

            let now = ISO8601DateFormatter().string(from: Date())
            try db.execute(
                sql: "INSERT INTO schema_version (version, migrated_at) VALUES (?, ?)",
                arguments: [1, now]
            )
        }

        migrator.registerMigration("v2") { db in
            try db.create(table: "tags") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("color_hex", .text).notNull()
                t.column("created_at", .text).notNull()
            }

            try db.create(table: "transaction_tags") { t in
                t.column("transaction_id", .text).notNull()
                    .references("transactions", onDelete: .cascade)
                t.column("tag_id", .text).notNull()
                    .references("tags", onDelete: .cascade)
                t.primaryKey(["transaction_id", "tag_id"])
            }

            try db.create(
                index: "idx_transaction_tags_transaction_id",
                on: "transaction_tags",
                columns: ["transaction_id"]
            )
            try db.create(
                index: "idx_transaction_tags_tag_id",
                on: "transaction_tags",
                columns: ["tag_id"]
            )
        }

        migrator.registerMigration("v3") { db in
            try db.create(table: "reminders") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("amount", .integer).notNull()
                t.column("type", .text).notNull().defaults(to: "expense")
                t.column("category_id", .text)
                    .references("categories", onDelete: .setNull)
                t.column("note", .text)
                t.column("frequency", .text).notNull().defaults(to: "monthly")
                t.column("trigger_day", .integer)
                t.column("trigger_hour", .integer).notNull().defaults(to: 9)
                t.column("trigger_minute", .integer).notNull().defaults(to: 0)
                t.column("is_enabled", .boolean).notNull().defaults(to: true)
                t.column("created_at", .text).notNull()
            }
        }

        migrator.registerMigration("v4") { db in
            try db.create(table: "budgets") { t in
                t.column("id", .text).primaryKey()
                t.column("amount", .integer).notNull()
                t.column("category_id", .text)
                    .references("categories", onDelete: .cascade)
                t.column("created_at", .text).notNull()
                t.column("updated_at", .text).notNull()
            }

            try db.create(
                index: "idx_budgets_category_id",
                on: "budgets",
                columns: ["category_id"],
                unique: true
            )
        }

        migrator.registerMigration("v5") { db in
            try db.create(table: "transaction_templates") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("amount", .integer).notNull()
                t.column("type", .text).notNull().defaults(to: "expense")
                t.column("category_id", .text).notNull()
                    .references("categories", onDelete: .cascade)
                t.column("note", .text)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
                t.column("created_at", .text).notNull()
            }
        }

        try migrator.migrate(dbQueue)
    }

    func seedDefaultCategories() throws {
        try dbQueue.write { db in
            let count = try Category.fetchCount(db)
            guard count == 0 else { return }

            let expenseCategories = Self.loadCategoriesFromBundle(filename: "categories-expense", type: "expense")
            let incomeCategories = Self.loadCategoriesFromBundle(filename: "categories-income", type: "income")

            for category in expenseCategories + incomeCategories {
                try category.insert(db)
            }
        }
    }

    func seedDefaultSettings() throws {
        try dbQueue.write { db in
            let existing = try Setting.fetchOne(db, key: "currency")
            guard existing == nil else { return }

            let currencyCode = Locale.current.currency?.identifier ?? "CNY"
            try Setting(key: "currency", value: currencyCode).insert(db)
        }
    }

    private static func loadCategoriesFromBundle(filename: String, type: String) -> [Category] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            assertionFailure("Missing bundle resource: \(filename).json")
            AppLogger.data.error("Missing bundle resource: \(filename).json")
            return []
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            assertionFailure("Failed to read \(filename).json: \(error)")
            AppLogger.data.error("Failed to read \(filename).json: \(error.localizedDescription)")
            return []
        }

        struct CategoryJSON: Decodable {
            let name_key: String
            let icon_name: String
            let color_hex: String
            let type: String
            let sort_order: Int
        }

        do {
            let items = try JSONDecoder().decode([CategoryJSON].self, from: data)
            return items.map { item in
                Category(
                    nameKey: item.name_key,
                    iconName: item.icon_name,
                    colorHex: item.color_hex,
                    type: item.type,
                    sortOrder: item.sort_order
                )
            }
        } catch {
            assertionFailure("Failed to decode \(filename).json: \(error)")
            AppLogger.data.error("Failed to decode \(filename).json: \(error.localizedDescription)")
            return []
        }
    }
}
