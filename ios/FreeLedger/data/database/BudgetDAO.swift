import Foundation
import GRDB

struct BudgetDAO {
    let dbQueue: DatabaseQueue

    func getAll() throws -> [Budget] {
        try dbQueue.read { db in
            try Budget.order(Budget.Columns.createdAt.asc).fetchAll(db)
        }
    }

    func getOverall() throws -> Budget? {
        try dbQueue.read { db in
            try Budget
                .filter(Budget.Columns.categoryId == nil)
                .fetchOne(db)
        }
    }

    func getByCategoryId(_ categoryId: String) throws -> Budget? {
        try dbQueue.read { db in
            try Budget
                .filter(Budget.Columns.categoryId == categoryId)
                .fetchOne(db)
        }
    }

    func getCategoryBudgets() throws -> [Budget] {
        try dbQueue.read { db in
            try Budget
                .filter(Budget.Columns.categoryId != nil)
                .order(Budget.Columns.createdAt.asc)
                .fetchAll(db)
        }
    }

    func insert(_ budget: Budget) throws {
        try dbQueue.write { db in
            try budget.insert(db)
        }
    }

    func update(_ budget: Budget) throws {
        try dbQueue.write { db in
            try budget.update(db)
        }
    }

    func delete(id: String) throws {
        try dbQueue.write { db in
            _ = try Budget.deleteOne(db, key: id)
        }
    }

    func upsertOverall(amount: Int64) throws {
        try dbQueue.write { db in
            if var existing = try Budget
                .filter(Budget.Columns.categoryId == nil)
                .fetchOne(db) {
                existing.amount = amount
                existing.updatedAt = AppDateFormatter.isoNow()
                try existing.update(db)
            } else {
                let budget = Budget(amount: amount, categoryId: nil)
                try budget.insert(db)
            }
        }
    }

    func upsertCategoryBudget(categoryId: String, amount: Int64) throws {
        try dbQueue.write { db in
            if var existing = try Budget
                .filter(Budget.Columns.categoryId == categoryId)
                .fetchOne(db) {
                existing.amount = amount
                existing.updatedAt = AppDateFormatter.isoNow()
                try existing.update(db)
            } else {
                let budget = Budget(amount: amount, categoryId: categoryId)
                try budget.insert(db)
            }
        }
    }
}
