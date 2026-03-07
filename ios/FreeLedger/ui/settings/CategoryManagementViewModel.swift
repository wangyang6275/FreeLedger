import Foundation
import Observation

@Observable
final class CategoryManagementViewModel {
    var expenseCategories: [Category] = []
    var incomeCategories: [Category] = []
    var isExpenseTab: Bool = true
    var showDeleteDialog: Bool = false
    var deleteTarget: Category?
    var errorMessage: String?

    private let categoryRepository: CategoryRepositoryProtocol

    init(categoryRepository: CategoryRepositoryProtocol) {
        self.categoryRepository = categoryRepository
    }

    var currentCategories: [Category] {
        isExpenseTab ? expenseCategories : incomeCategories
    }

    func loadData() {
        do {
            expenseCategories = try categoryRepository.getExpenseCategories(sortedByUsage: false)
            incomeCategories = try categoryRepository.getIncomeCategories(sortedByUsage: false)
        } catch {
            AppLogger.ui.error("CategoryManagementVM loadData failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
        }
    }

    func deactivateCategory() {
        guard let cat = deleteTarget else { return }
        do {
            try categoryRepository.deactivate(id: cat.id)
            loadData()
        } catch {
            AppLogger.ui.error("CategoryManagementVM deactivate failed: \(error.localizedDescription)")
            errorMessage = L("error_delete_failed")
        }
        deleteTarget = nil
    }

    func categoryDisplayName(_ category: Category) -> String {
        if category.isCustom {
            return category.nameKey
        }
        return L(category.nameKey)
    }
}
