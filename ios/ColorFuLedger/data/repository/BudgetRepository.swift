import Foundation

protocol BudgetRepositoryProtocol {
    func getOverallBudget() throws -> Budget?
    func getCategoryBudgets() throws -> [Budget]
    func getAllBudgets() throws -> [Budget]
    func setOverallBudget(amount: Int64) throws
    func setCategoryBudget(categoryId: String, amount: Int64) throws
    func deleteBudget(id: String) throws
    func getBudgetForCategory(_ categoryId: String) throws -> Budget?
}

final class BudgetRepository: BudgetRepositoryProtocol {
    private let dao: BudgetDAO

    init(dao: BudgetDAO) {
        self.dao = dao
    }

    func getOverallBudget() throws -> Budget? {
        try dao.getOverall()
    }

    func getCategoryBudgets() throws -> [Budget] {
        try dao.getCategoryBudgets()
    }

    func getAllBudgets() throws -> [Budget] {
        try dao.getAll()
    }

    func setOverallBudget(amount: Int64) throws {
        try dao.upsertOverall(amount: amount)
    }

    func setCategoryBudget(categoryId: String, amount: Int64) throws {
        try dao.upsertCategoryBudget(categoryId: categoryId, amount: amount)
    }

    func deleteBudget(id: String) throws {
        try dao.delete(id: id)
    }

    func getBudgetForCategory(_ categoryId: String) throws -> Budget? {
        try dao.getByCategoryId(categoryId)
    }
}
