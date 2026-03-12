import Foundation
import Observation

struct CategoryBudgetItem: Identifiable {
    let id: String
    let category: Category
    let budget: Budget
    let spent: Int64
    var percentage: Double {
        budget.amount > 0 ? min(Double(spent) / Double(budget.amount) * 100.0, 100.0) : 0
    }
    var remaining: Int64 { max(budget.amount - spent, 0) }
    var isOverBudget: Bool { spent > budget.amount }
}

@Observable
final class BudgetViewModel {
    var overallBudget: Budget?
    var overallSpent: Int64 = 0
    var categoryBudgetItems: [CategoryBudgetItem] = []
    var expenseCategories: [Category] = []
    var currencyCode: String = "CNY"
    var errorMessage: String?

    var overallPercentage: Double {
        guard let budget = overallBudget, budget.amount > 0 else { return 0 }
        return min(Double(overallSpent) / Double(budget.amount) * 100.0, 100.0)
    }

    var overallRemaining: Int64 {
        guard let budget = overallBudget else { return 0 }
        return max(budget.amount - overallSpent, 0)
    }

    var isOverallOverBudget: Bool {
        guard let budget = overallBudget else { return false }
        return overallSpent > budget.amount
    }

    private let budgetRepository: BudgetRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    init(budgetRepository: BudgetRepositoryProtocol,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
    }

    func loadData() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        do {
            currencyCode = try settingsRepository.getCurrency()
            overallBudget = try budgetRepository.getOverallBudget()
            let summary = try transactionRepository.getMonthlySummary(year: year, month: month)
            overallSpent = summary.totalExpense

            let catBudgets = try budgetRepository.getCategoryBudgets()
            let categoryDict = try categoryRepository.getAllAsDict()
            let breakdowns = try transactionRepository.getCategoryBreakdown(year: year, month: month, type: "expense")
            let spentMap = Dictionary(uniqueKeysWithValues: breakdowns.map { ($0.categoryId, $0.total) })

            categoryBudgetItems = catBudgets.compactMap { budget in
                guard let catId = budget.categoryId, let cat = categoryDict[catId] else { return nil }
                return CategoryBudgetItem(
                    id: budget.id,
                    category: cat,
                    budget: budget,
                    spent: spentMap[catId] ?? 0
                )
            }

            expenseCategories = try categoryRepository.getExpenseCategories(sortedByUsage: true)
        } catch {
            AppLogger.ui.error("BudgetViewModel loadData failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
        }
    }

    func setOverallBudget(amount: Int64) {
        do {
            try budgetRepository.setOverallBudget(amount: amount)
            loadData()
        } catch {
            AppLogger.ui.error("BudgetViewModel setOverallBudget failed: \(error.localizedDescription)")
            errorMessage = L("error_save_failed")
        }
    }

    func deleteOverallBudget() {
        guard let budget = overallBudget else { return }
        do {
            try budgetRepository.deleteBudget(id: budget.id)
            loadData()
        } catch {
            AppLogger.ui.error("BudgetViewModel deleteOverallBudget failed: \(error.localizedDescription)")
            errorMessage = L("error_delete_failed")
        }
    }

    func setCategoryBudget(categoryId: String, amount: Int64) {
        do {
            try budgetRepository.setCategoryBudget(categoryId: categoryId, amount: amount)
            loadData()
        } catch {
            AppLogger.ui.error("BudgetViewModel setCategoryBudget failed: \(error.localizedDescription)")
            errorMessage = L("error_save_failed")
        }
    }

    func deleteCategoryBudget(id: String) {
        do {
            try budgetRepository.deleteBudget(id: id)
            loadData()
        } catch {
            AppLogger.ui.error("BudgetViewModel deleteCategoryBudget failed: \(error.localizedDescription)")
            errorMessage = L("error_delete_failed")
        }
    }

    /// 返回尚未设置预算的分类列表
    func availableCategories() -> [Category] {
        let usedCatIds = Set(categoryBudgetItems.map { $0.category.id })
        return expenseCategories.filter { !usedCatIds.contains($0.id) }
    }
}
