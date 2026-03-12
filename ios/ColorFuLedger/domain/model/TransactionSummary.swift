import Foundation

struct TransactionSummary {
    let totalExpense: Int64
    let totalIncome: Int64

    var balance: Int64 {
        totalIncome - totalExpense
    }

    static let empty = TransactionSummary(totalExpense: 0, totalIncome: 0)
}
