import Foundation
import Observation

@Observable
final class AnnualReportViewModel {
    var currentYear: Int
    var summary: TransactionSummary = TransactionSummary(totalExpense: 0, totalIncome: 0)
    var monthlySummaries: [MonthlyTrend] = []
    var expenseBreakdown: [CategoryBreakdown] = []
    var currencyCode: String = "CNY"
    var transactionCount: Int = 0
    var errorMessage: String?

    var isEmpty: Bool {
        summary.totalExpense == 0 && summary.totalIncome == 0
    }

    var netAmount: Int64 {
        summary.totalIncome - summary.totalExpense
    }

    var avgMonthlyExpense: Int64 {
        let activeMonths = monthlySummaries.filter { $0.expense > 0 }.count
        return activeMonths > 0 ? summary.totalExpense / Int64(activeMonths) : 0
    }

    var avgMonthlyIncome: Int64 {
        let activeMonths = monthlySummaries.filter { $0.income > 0 }.count
        return activeMonths > 0 ? summary.totalIncome / Int64(activeMonths) : 0
    }

    var highestExpenseMonth: MonthlyTrend? {
        monthlySummaries.max(by: { $0.expense < $1.expense })
    }

    var lowestExpenseMonth: MonthlyTrend? {
        monthlySummaries.filter { $0.expense > 0 }.min(by: { $0.expense < $1.expense })
    }

    private let transactionRepository: TransactionRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    init(transactionRepository: TransactionRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.settingsRepository = settingsRepository
        self.currentYear = Calendar.current.component(.year, from: Date())
    }

    func loadData() {
        do {
            currencyCode = try settingsRepository.getCurrency()
            summary = try transactionRepository.getAnnualSummary(year: currentYear)
            monthlySummaries = try transactionRepository.getAnnualMonthlySummaries(year: currentYear)
            expenseBreakdown = try transactionRepository.getAnnualCategoryBreakdown(
                year: currentYear, type: TransactionType.expense.rawValue
            )
            transactionCount = try transactionRepository.getAll().filter {
                $0.createdAt.hasPrefix(String(currentYear))
            }.count
        } catch {
            AppLogger.ui.error("AnnualReportViewModel loadData failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
        }
    }

    func previousYear() {
        currentYear -= 1
        loadData()
    }

    func nextYear() {
        currentYear += 1
        loadData()
    }
}
