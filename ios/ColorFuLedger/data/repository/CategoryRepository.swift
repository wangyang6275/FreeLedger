import Foundation

protocol CategoryRepositoryProtocol {
    func getExpenseCategories(sortedByUsage: Bool) throws -> [Category]
    func getIncomeCategories(sortedByUsage: Bool) throws -> [Category]
    func incrementUsageCount(id: String) throws
    func getAllAsDict() throws -> [String: Category]
    func create(_ category: Category) throws
    func update(_ category: Category) throws
    func deactivate(id: String) throws
    func getNextSortOrder(type: String) throws -> Int
}

final class CategoryRepository: CategoryRepositoryProtocol {
    private let dao: CategoryDAO

    init(dao: CategoryDAO) {
        self.dao = dao
    }

    func getExpenseCategories(sortedByUsage: Bool = true) throws -> [Category] {
        try dao.getByType("expense", sortedByUsage: sortedByUsage)
    }

    func getIncomeCategories(sortedByUsage: Bool = true) throws -> [Category] {
        try dao.getByType("income", sortedByUsage: sortedByUsage)
    }

    func incrementUsageCount(id: String) throws {
        try dao.incrementUsageCount(id: id)
    }

    func getAllAsDict() throws -> [String: Category] {
        try dao.getAllAsDict()
    }

    func create(_ category: Category) throws {
        try dao.insert(category)
    }

    func update(_ category: Category) throws {
        try dao.update(category)
    }

    func deactivate(id: String) throws {
        try dao.deactivate(id: id)
    }

    func getNextSortOrder(type: String) throws -> Int {
        try dao.getNextSortOrder(type: type)
    }
}
