import Foundation
import Observation

@Observable
final class HomeViewModel {
    var summary: TransactionSummary = .empty
    var groupedTransactions: [(String, [Transaction])] = []
    var categoryDict: [String: Category] = [:]
    var currencyCode: String = "CNY"
    var monthTitle: String = ""
    var isEmpty: Bool = true
    var errorMessage: String?

    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    init(transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
    }

    func loadData() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        monthTitle = AppDateFormatter.formatMonthTitle(now)

        do {
            currencyCode = try settingsRepository.getCurrency()
            let transactions = try transactionRepository.getTransactionsForMonth(year: year, month: month)
            summary = try transactionRepository.getMonthlySummary(year: year, month: month)
            categoryDict = try categoryRepository.getAllAsDict()
            groupedTransactions = AppDateFormatter.groupTransactionsByDate(transactions)
            isEmpty = transactions.isEmpty
        } catch {
            errorMessage = String(localized: "error_load_failed")
            isEmpty = true
        }
    }
}
