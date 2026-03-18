import Foundation
@testable import ColorFuLedger

// MARK: - Mock Repositories

final class MockTransactionRepository: TransactionRepositoryProtocol {
    var transactions: [Transaction] = []
    var summary: TransactionSummary = .empty
    var categoryBreakdown: [CategoryBreakdown] = []
    var monthlyTrends: [MonthlyTrend] = []
    var tags: [Tag] = []
    var shouldThrow = false

    func insert(amount: Int64, type: String, categoryId: String, note: String?, tagIds: [String]) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        let tx = Transaction(amount: amount, type: type, categoryId: categoryId, note: note)
        transactions.append(tx)
    }

    func getAll() throws -> [Transaction] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return transactions
    }

    func getById(_ id: String) throws -> Transaction? {
        if shouldThrow { throw AppError.databaseError("mock") }
        return transactions.first { $0.id == id }
    }

    func update(_ transaction: Transaction) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        if let idx = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[idx] = transaction
        }
    }

    func delete(id: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        transactions.removeAll { $0.id == id }
    }

    func getTransactionsForMonth(year: Int, month: Int) throws -> [Transaction] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return transactions
    }

    func getMonthlySummary(year: Int, month: Int) throws -> TransactionSummary {
        if shouldThrow { throw AppError.databaseError("mock") }
        return summary
    }

    func getTagsForTransaction(transactionId: String) throws -> [Tag] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return tags
    }

    func setTagsForTransaction(transactionId: String, tagIds: [String]) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
    }

    func getCategoryBreakdown(year: Int, month: Int, type: String) throws -> [CategoryBreakdown] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return categoryBreakdown
    }

    func getLast6MonthsSummary(fromYear: Int, fromMonth: Int) throws -> [MonthlyTrend] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return monthlyTrends
    }

    func search(keyword: String?, startDate: String?, endDate: String?, categoryId: String?, limit: Int) throws -> [Transaction] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return transactions.filter { tx in
            if let keyword, !keyword.isEmpty {
                return tx.note?.contains(keyword) ?? false
            }
            return true
        }
    }

    func getAnnualSummary(year: Int) throws -> TransactionSummary {
        if shouldThrow { throw AppError.databaseError("mock") }
        return summary
    }

    func getAnnualMonthlySummaries(year: Int) throws -> [MonthlyTrend] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return monthlyTrends
    }

    func getAnnualCategoryBreakdown(year: Int, type: String) throws -> [CategoryBreakdown] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return categoryBreakdown
    }

    func getDailySummaries(year: Int, month: Int) throws -> [DailySummary] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return []
    }

    func getTransactionsForDay(year: Int, month: Int, day: Int) throws -> [Transaction] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return transactions
    }
}

final class MockCategoryRepository: CategoryRepositoryProtocol {
    var expenseCategories: [Category] = []
    var incomeCategories: [Category] = []
    var categoryDict: [String: Category] = [:]
    var shouldThrow = false

    func getExpenseCategories(sortedByUsage: Bool) throws -> [Category] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return expenseCategories
    }

    func getIncomeCategories(sortedByUsage: Bool) throws -> [Category] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return incomeCategories
    }

    func incrementUsageCount(id: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
    }

    func getAllAsDict() throws -> [String: Category] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return categoryDict
    }

    func create(_ category: Category) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
    }

    func update(_ category: Category) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
    }

    func deactivate(id: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
    }

    func getNextSortOrder(type: String) throws -> Int {
        if shouldThrow { throw AppError.databaseError("mock") }
        return 0
    }
}

final class MockSettingsRepository: SettingsRepositoryProtocol {
    var currency = "CNY"
    var settings: [String: String] = [:]
    var shouldThrow = false

    func getCurrency() throws -> String {
        if shouldThrow { throw AppError.databaseError("mock") }
        return currency
    }

    func setCurrency(_ code: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        currency = code
    }

    func get(key: String) throws -> String? {
        if shouldThrow { throw AppError.databaseError("mock") }
        return settings[key]
    }

    func set(key: String, value: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        settings[key] = value
    }
}

final class MockTagRepository: TagRepositoryProtocol {
    var tags: [Tag] = []
    var transactionCounts: [String: Int] = [:]
    var tagBreakdown: [TagExpenseBreakdown] = []
    var tagTransactions: [Transaction] = []
    var shouldThrow = false

    func getAll() throws -> [Tag] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return tags
    }

    func getById(_ id: String) throws -> Tag? {
        if shouldThrow { throw AppError.databaseError("mock") }
        return tags.first { $0.id == id }
    }

    func create(_ tag: Tag) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        tags.append(tag)
    }

    func update(_ tag: Tag) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        if let idx = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[idx] = tag
        }
    }

    func delete(id: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        tags.removeAll { $0.id == id }
    }

    func getTagsForTransaction(transactionId: String) throws -> [Tag] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return []
    }

    func getTransactionCountPerTag() throws -> [String: Int] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return transactionCounts
    }

    func getTransactionsForTag(tagId: String) throws -> [Transaction] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return tagTransactions
    }

    func getTagExpenseBreakdown(year: Int, month: Int) throws -> [TagExpenseBreakdown] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return tagBreakdown
    }
}

final class MockTransactionTemplateRepository: TransactionTemplateRepositoryProtocol {
    var templates: [TransactionTemplate] = []
    var shouldThrow = false

    func getAll() throws -> [TransactionTemplate] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return templates
    }

    func getById(_ id: String) throws -> TransactionTemplate? {
        if shouldThrow { throw AppError.databaseError("mock") }
        return templates.first { $0.id == id }
    }

    func insert(_ template: TransactionTemplate) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        templates.append(template)
    }

    func update(_ template: TransactionTemplate) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        if let idx = templates.firstIndex(where: { $0.id == template.id }) {
            templates[idx] = template
        }
    }

    func delete(id: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        templates.removeAll { $0.id == id }
    }
}

final class MockBudgetRepository: BudgetRepositoryProtocol {
    var overallBudget: Budget?
    var categoryBudgets: [Budget] = []
    var allBudgets: [Budget] = []
    var shouldThrow = false

    func getOverallBudget() throws -> Budget? {
        if shouldThrow { throw AppError.databaseError("mock") }
        return overallBudget
    }

    func getCategoryBudgets() throws -> [Budget] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return categoryBudgets
    }

    func getAllBudgets() throws -> [Budget] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return allBudgets
    }

    func setOverallBudget(amount: Int64) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        overallBudget = Budget(amount: amount)
    }

    func setCategoryBudget(categoryId: String, amount: Int64) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        let budget = Budget(amount: amount, categoryId: categoryId)
        categoryBudgets.append(budget)
    }

    func deleteBudget(id: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        if overallBudget?.id == id { overallBudget = nil }
        categoryBudgets.removeAll { $0.id == id }
    }

    func getBudgetForCategory(_ categoryId: String) throws -> Budget? {
        if shouldThrow { throw AppError.databaseError("mock") }
        return categoryBudgets.first { $0.categoryId == categoryId }
    }
}

final class MockReminderRepository: ReminderRepositoryProtocol {
    var reminders: [Reminder] = []
    var shouldThrow = false

    func getAll() throws -> [Reminder] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return reminders
    }

    func getEnabled() throws -> [Reminder] {
        if shouldThrow { throw AppError.databaseError("mock") }
        return reminders.filter(\.isEnabled)
    }

    func getById(_ id: String) throws -> Reminder? {
        if shouldThrow { throw AppError.databaseError("mock") }
        return reminders.first { $0.id == id }
    }

    func create(_ reminder: Reminder) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        reminders.append(reminder)
    }

    func update(_ reminder: Reminder) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx] = reminder
        }
    }

    func delete(id: String) throws {
        if shouldThrow { throw AppError.databaseError("mock") }
        reminders.removeAll { $0.id == id }
    }
}
