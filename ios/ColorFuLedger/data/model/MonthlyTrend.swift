import Foundation

struct MonthlyTrend: Identifiable {
    let id: String
    let year: Int
    let month: Int
    let monthLabel: String
    let expense: Int64
    let income: Int64

    init(year: Int, month: Int, monthLabel: String, expense: Int64, income: Int64) {
        self.id = "\(year)-\(month)"
        self.year = year
        self.month = month
        self.monthLabel = monthLabel
        self.expense = expense
        self.income = income
    }
}
