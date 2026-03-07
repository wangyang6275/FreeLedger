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
    var overallBudget: Budget?

    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol?

    init(transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         budgetRepository: BudgetRepositoryProtocol? = nil) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        self.budgetRepository = budgetRepository
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
            overallBudget = try budgetRepository?.getOverallBudget()
            syncWidgetData(transactions: transactions)
        } catch {
            AppLogger.ui.error("HomeViewModel loadData failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
            isEmpty = true
        }
    }

    private func syncWidgetData(transactions: [Transaction]) {
        let recent = Array(transactions.prefix(5)).map { tx in
            let cat = categoryDict[tx.categoryId]
            return WidgetTransactionItem(
                categoryName: cat.map { L($0.nameKey) } ?? "—",
                categoryIcon: cat?.iconName ?? "questionmark",
                categoryColor: cat?.colorHex ?? "#E0E0E0",
                amount: tx.amount,
                isExpense: tx.type == TransactionType.expense.rawValue,
                note: tx.note,
                time: AppDateFormatter.formatTime(tx.createdAt)
            )
        }
        let data = WidgetData(
            totalExpense: summary.totalExpense,
            totalIncome: summary.totalIncome,
            balance: summary.balance,
            monthTitle: monthTitle,
            currencyCode: currencyCode,
            recentTransactions: recent,
            updatedAt: Date()
        )
        WidgetDataBridge.write(data)
    }
}
