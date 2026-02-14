import Foundation
import GRDB

struct CategoryDAO {
    let dbQueue: DatabaseQueue

    func getAll() throws -> [Category] {
        try dbQueue.read { db in
            try Category.fetchAll(db)
        }
    }

    func getByType(_ type: String, sortedByUsage: Bool = true) throws -> [Category] {
        try dbQueue.read { db in
            if sortedByUsage {
                return try Category
                    .filter(Category.Columns.type == type)
                    .filter(Category.Columns.isActive == true)
                    .order(Category.Columns.usageCount.desc, Category.Columns.sortOrder.asc)
                    .fetchAll(db)
            } else {
                return try Category
                    .filter(Category.Columns.type == type)
                    .filter(Category.Columns.isActive == true)
                    .order(Category.Columns.sortOrder.asc)
                    .fetchAll(db)
            }
        }
    }

    func insert(_ category: Category) throws {
        try dbQueue.write { db in
            try category.insert(db)
        }
    }

    func getById(_ id: String) throws -> Category? {
        try dbQueue.read { db in
            try Category.fetchOne(db, key: id)
        }
    }

    func getAllAsDict() throws -> [String: Category] {
        try dbQueue.read { db in
            let categories = try Category.fetchAll(db)
            return Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        }
    }

    func update(_ category: Category) throws {
        try dbQueue.write { db in
            try category.update(db)
        }
    }

    func deactivate(id: String) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE categories SET is_active = 0 WHERE id = ?",
                arguments: [id]
            )
        }
    }

    func getNextSortOrder(type: String) throws -> Int {
        try dbQueue.read { db in
            let maxOrder = try Int.fetchOne(
                db,
                sql: "SELECT MAX(sort_order) FROM categories WHERE type = ?",
                arguments: [type]
            )
            return (maxOrder ?? 0) + 1
        }
    }

    func incrementUsageCount(id: String) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE categories SET usage_count = usage_count + 1 WHERE id = ?",
                arguments: [id]
            )
        }
    }
}
