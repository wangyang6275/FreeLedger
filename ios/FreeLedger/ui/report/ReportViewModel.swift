import Foundation
import Observation

@Observable
final class ReportViewModel {
    var currentYear: Int
    var currentMonth: Int
    var summary: TransactionSummary = TransactionSummary(totalExpense: 0, totalIncome: 0)
    var expenseBreakdown: [CategoryBreakdown] = []
    var trendData: [MonthlyTrend] = []
    var tagBreakdown: [TagExpenseBreakdown] = []
    var selectedCategoryId: String?
    var currencyCode: String = "CNY"
    var errorMessage: String?

    private let transactionRepository: TransactionRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        return f
    }()

    var isEmpty: Bool {
        summary.totalExpense == 0 && summary.totalIncome == 0
    }

    var monthTitle: String {
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = currentMonth
        comps.day = 1
        guard let date = Calendar.current.date(from: comps) else { return "" }
        return Self.monthFormatter.string(from: date)
    }

    init(transactionRepository: TransactionRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.settingsRepository = settingsRepository
        self.tagRepository = tagRepository
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        self.currentYear = now.year ?? 2026
        self.currentMonth = now.month ?? 1
    }

    func loadData() {
        do {
            currencyCode = try settingsRepository.getCurrency()
        } catch {
            currencyCode = "CNY"
        }

        do {
            summary = try transactionRepository.getMonthlySummary(year: currentYear, month: currentMonth)
            expenseBreakdown = try transactionRepository.getCategoryBreakdown(
                year: currentYear, month: currentMonth, type: TransactionType.expense.rawValue
            )
            trendData = try transactionRepository.getLast6MonthsSummary(
                fromYear: currentYear, fromMonth: currentMonth
            )
            tagBreakdown = try tagRepository.getTagExpenseBreakdown(
                year: currentYear, month: currentMonth
            )
        } catch {
            errorMessage = String(localized: "error_load_failed")
        }
    }

    func previousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
        selectedCategoryId = nil
        loadData()
    }

    func nextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
        selectedCategoryId = nil
        loadData()
    }

    func selectCategory(_ id: String?) {
        if selectedCategoryId == id {
            selectedCategoryId = nil
        } else {
            selectedCategoryId = id
        }
    }
}
