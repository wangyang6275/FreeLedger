import Foundation
import Observation

@Observable
final class TagDetailViewModel {
    var tag: Tag
    var transactions: [Transaction] = []
    var categoryDict: [String: Category] = [:]
    var currencyCode: String = "CNY"
    var errorMessage: String?

    private let tagRepository: TagRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    private static let dateDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f
    }()

    init(tag: Tag,
         tagRepository: TagRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.tag = tag
        self.tagRepository = tagRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
    }

    var totalExpense: Int64 {
        transactions
            .filter { $0.type == TransactionType.expense.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncome: Int64 {
        transactions
            .filter { $0.type == TransactionType.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { tx -> String in
            guard let date = AppDateFormatter.parseISO(tx.createdAt) else { return "" }
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return L("date_today")
            } else if calendar.isDateInYesterday(date) {
                return L("date_yesterday")
            } else {
                return Self.dateDisplayFormatter.string(from: date)
            }
        }
        return grouped.sorted { lhs, rhs in
            guard let lDate = lhs.1.first?.createdAt, let rDate = rhs.1.first?.createdAt else { return false }
            return lDate > rDate
        }
    }

    func loadData() {
        do {
            currencyCode = try settingsRepository.getCurrency()
        } catch {
            currencyCode = "CNY"
        }

        do {
            transactions = try tagRepository.getTransactionsForTag(tagId: tag.id)
            categoryDict = try categoryRepository.getAllAsDict()
        } catch {
            errorMessage = L("error_load_failed")
        }
    }
}
