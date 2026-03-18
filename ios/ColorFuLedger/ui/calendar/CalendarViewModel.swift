import Foundation
import Observation

@Observable
final class CalendarViewModel {
    var currentYear: Int
    var currentMonth: Int
    var dailySummaries: [Int: DailySummary] = [:]
    var selectedDay: Int?
    var selectedDayTransactions: [Transaction] = []
    var categoryDict: [String: Category] = [:]
    var currencyCode: String = "CNY"
    var monthTitle: String = ""
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
        let now = Date()
        let calendar = Calendar.current
        self.currentYear = calendar.component(.year, from: now)
        self.currentMonth = calendar.component(.month, from: now)
    }

    func loadData() {
        do {
            currencyCode = try settingsRepository.getCurrency()
            categoryDict = try categoryRepository.getAllAsDict()
            let summaries = try transactionRepository.getDailySummaries(year: currentYear, month: currentMonth)
            dailySummaries = Dictionary(uniqueKeysWithValues: summaries.map { ($0.day, $0) })
            updateMonthTitle()
            if let day = selectedDay {
                loadDayTransactions(day)
            }
        } catch {
            AppLogger.ui.error("CalendarViewModel loadData failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
        }
    }

    func previousMonth() {
        currentMonth -= 1
        if currentMonth < 1 {
            currentMonth = 12
            currentYear -= 1
        }
        selectedDay = nil
        selectedDayTransactions = []
        loadData()
    }

    func nextMonth() {
        let now = Date()
        let calendar = Calendar.current
        let nowYear = calendar.component(.year, from: now)
        let nowMonth = calendar.component(.month, from: now)
        if currentYear == nowYear && currentMonth == nowMonth { return }
        currentMonth += 1
        if currentMonth > 12 {
            currentMonth = 1
            currentYear += 1
        }
        selectedDay = nil
        selectedDayTransactions = []
        loadData()
    }

    var isCurrentMonth: Bool {
        let now = Date()
        let calendar = Calendar.current
        return currentYear == calendar.component(.year, from: now) &&
               currentMonth == calendar.component(.month, from: now)
    }

    func selectDay(_ day: Int) {
        if selectedDay == day {
            selectedDay = nil
            selectedDayTransactions = []
            return
        }
        selectedDay = day
        loadDayTransactions(day)
    }

    private func loadDayTransactions(_ day: Int) {
        do {
            selectedDayTransactions = try transactionRepository.getTransactionsForDay(
                year: currentYear, month: currentMonth, day: day
            )
        } catch {
            AppLogger.ui.error("CalendarViewModel loadDayTransactions failed: \(error.localizedDescription)")
            selectedDayTransactions = []
        }
    }

    private func updateMonthTitle() {
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = currentMonth
        comps.day = 1
        if let date = Calendar.current.date(from: comps) {
            monthTitle = AppDateFormatter.formatMonthTitle(date)
        }
    }

    var daysInMonth: Int {
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }

    var firstWeekdayOfMonth: Int {
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) else {
            return 1
        }
        return calendar.component(.weekday, from: date)
    }

    var todayDay: Int? {
        let now = Date()
        let calendar = Calendar.current
        guard calendar.component(.year, from: now) == currentYear,
              calendar.component(.month, from: now) == currentMonth else {
            return nil
        }
        return calendar.component(.day, from: now)
    }

    func categoryName(for id: String) -> String {
        guard let cat = categoryDict[id] else { return "—" }
        return cat.isCustom ? cat.nameKey : L(cat.nameKey)
    }
}
