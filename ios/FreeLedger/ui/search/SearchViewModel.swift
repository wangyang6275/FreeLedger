import Foundation
import Observation

@Observable
final class SearchViewModel {
    var searchText: String = ""
    var startDate: Date?
    var endDate: Date?
    var selectedCategoryId: String?
    var results: [Transaction] = []
    var categoryDict: [String: Category] = [:]
    var categories: [Category] = []
    var currencyCode: String = "CNY"
    var hasSearched: Bool = false
    var errorMessage: String?

    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    var isEmpty: Bool {
        hasSearched && results.isEmpty
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty || startDate != nil || endDate != nil || selectedCategoryId != nil
    }

    init(transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
    }

    func loadInitialData() {
        do {
            currencyCode = try settingsRepository.getCurrency()
            categoryDict = try categoryRepository.getAllAsDict()
            let expense = try categoryRepository.getExpenseCategories(sortedByUsage: false)
            let income = try categoryRepository.getIncomeCategories(sortedByUsage: false)
            categories = expense + income
        } catch {
            AppLogger.ui.error("SearchViewModel loadInitialData failed: \(error.localizedDescription)")
            currencyCode = "CNY"
        }
    }

    func performSearch() {
        let startISO = startDate.map { AppDateFormatter.formatISO($0) }
        let endISO = endDate.map { AppDateFormatter.formatISO(Calendar.current.date(byAdding: .day, value: 1, to: $0) ?? $0) }
        let keyword = searchText.isEmpty ? nil : searchText

        do {
            results = try transactionRepository.search(
                keyword: keyword,
                startDate: startISO,
                endDate: endISO,
                categoryId: selectedCategoryId,
                limit: 200
            )
            hasSearched = true
        } catch {
            AppLogger.ui.error("SearchViewModel performSearch failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
        }
    }

    func clearFilters() {
        searchText = ""
        startDate = nil
        endDate = nil
        selectedCategoryId = nil
        results = []
        hasSearched = false
    }

    func categoryName(for id: String) -> String {
        guard let cat = categoryDict[id] else { return "—" }
        if cat.isCustom {
            return cat.nameKey
        }
        return L(cat.nameKey)
    }
}
