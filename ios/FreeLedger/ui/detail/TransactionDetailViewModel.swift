import Foundation
import Observation

@Observable
final class TransactionDetailViewModel {
    var transaction: Transaction
    var category: Category?
    var allCategories: [Category] = []
    var tags: [Tag] = []
    var currencyCode: String = "CNY"
    var isEditing: Bool = false
    var showDeleteDialog: Bool = false
    var didDelete: Bool = false
    var errorMessage: String?

    // Edit state
    var editAmountString: String = ""
    var editNote: String = ""
    var editCategoryId: String = ""
    var editIsExpense: Bool = true
    var editTagIds: Set<String> = []

    private static let dateDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f
    }()

    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    let tagRepository: TagRepositoryProtocol

    init(transaction: Transaction,
         category: Category?,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol) {
        self.transaction = transaction
        self.category = category
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        self.tagRepository = tagRepository
    }

    func loadData() {
        do {
            currencyCode = try settingsRepository.getCurrency()
        } catch {
            currencyCode = "CNY"
        }
        do {
            tags = try transactionRepository.getTagsForTransaction(transactionId: transaction.id)
        } catch {
            tags = []
        }
    }

    var formattedAmount: String {
        AmountFormatter.format(transaction.amount, currencyCode: currencyCode)
    }

    var formattedDate: String {
        guard let date = AppDateFormatter.parseISO(transaction.createdAt) else { return "" }
        let calendar = Calendar.current
        let dateStr: String
        if calendar.isDateInToday(date) {
            dateStr = String(localized: "date_today")
        } else if calendar.isDateInYesterday(date) {
            dateStr = String(localized: "date_yesterday")
        } else {
            dateStr = Self.dateDisplayFormatter.string(from: date)
        }
        let timeStr = AppDateFormatter.formatTime(transaction.createdAt)
        return "\(dateStr) \(timeStr)"
    }

    var categoryName: String {
        guard let cat = category else { return "—" }
        return String(localized: String.LocalizationValue(cat.nameKey))
    }

    var isExpense: Bool {
        transaction.type == TransactionType.expense.rawValue
    }

    // MARK: - Edit

    func startEditing() {
        editAmountString = String(format: "%.2f", Double(transaction.amount) / 100.0)
        if editAmountString.hasSuffix(".00") {
            editAmountString = String(editAmountString.dropLast(3))
        }
        editNote = transaction.note ?? ""
        editCategoryId = transaction.categoryId
        editIsExpense = isExpense
        editTagIds = Set(tags.map { $0.id })

        do {
            if editIsExpense {
                allCategories = try categoryRepository.getExpenseCategories(sortedByUsage: true)
            } else {
                allCategories = try categoryRepository.getIncomeCategories(sortedByUsage: true)
            }
        } catch {
            allCategories = []
        }

        isEditing = true
    }

    func cancelEditing() {
        isEditing = false
    }

    func saveEdit() {
        let cents = AmountFormatter.toCents(editAmountString)
        guard cents > 0 else {
            errorMessage = String(localized: "error_invalid_amount")
            return
        }

        let noteText = editNote.trimmingCharacters(in: .whitespacesAndNewlines)
        var updated = transaction
        updated.amount = cents
        updated.categoryId = editCategoryId
        updated.note = noteText.isEmpty ? nil : noteText
        updated.type = editIsExpense ? TransactionType.expense.rawValue : TransactionType.income.rawValue
        updated.updatedAt = Transaction.currentISO()

        do {
            try transactionRepository.update(updated)
            try transactionRepository.setTagsForTransaction(
                transactionId: updated.id,
                tagIds: Array(editTagIds)
            )
            transaction = updated

            // Refresh category info
            if let dict = try? categoryRepository.getAllAsDict() {
                category = dict[updated.categoryId]
            }

            // Refresh tags
            tags = (try? transactionRepository.getTagsForTransaction(transactionId: updated.id)) ?? []

            isEditing = false
        } catch {
            errorMessage = String(localized: "error_save_failed")
        }
    }

    func toggleEditType() {
        editIsExpense.toggle()
        do {
            if editIsExpense {
                allCategories = try categoryRepository.getExpenseCategories(sortedByUsage: true)
            } else {
                allCategories = try categoryRepository.getIncomeCategories(sortedByUsage: true)
            }
            // Reset category selection if current doesn't match new type
            if !allCategories.contains(where: { $0.id == editCategoryId }) {
                editCategoryId = allCategories.first?.id ?? ""
            }
        } catch {
            allCategories = []
        }
    }

    // MARK: - Delete

    func deleteTransaction() {
        do {
            try transactionRepository.delete(id: transaction.id)
            didDelete = true
        } catch {
            errorMessage = String(localized: "error_delete_failed")
        }
    }
}
