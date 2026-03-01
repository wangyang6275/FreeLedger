import Foundation
import Observation

@Observable
final class RecordViewModel {
    var amountString: String = ""
    var isExpense: Bool = true
    var note: String = ""
    var isNoteExpanded: Bool = false
    var categories: [Category] = []
    var isSaving: Bool = false
    var didSave: Bool = false
    var errorMessage: String?

    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    var currencySymbol: String = "¥"

    var amountInCents: Int64 {
        AmountFormatter.toCents(amountString)
    }

    var canSave: Bool {
        amountInCents > 0
    }

    var displayAmount: String {
        AmountFormatter.formatDisplay(amountString, currencySymbol: currencySymbol)
    }

    init(transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
    }

    func loadCategories() {
        do {
            if isExpense {
                categories = try categoryRepository.getExpenseCategories(sortedByUsage: true)
            } else {
                categories = try categoryRepository.getIncomeCategories(sortedByUsage: true)
            }
        } catch {
            categories = []
        }
    }

    func loadCurrency() {
        do {
            let code = try settingsRepository.getCurrency()
            let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code]))
            currencySymbol = locale.currencySymbol ?? "¥"
        } catch {
            currencySymbol = "¥"
        }
    }

    func toggleType() {
        isExpense.toggle()
        loadCategories()
    }

    func saveTransaction(categoryId: String, tagIds: [String] = []) {
        guard canSave else { return }
        isSaving = true

        do {
            let type = isExpense ? TransactionType.expense.rawValue : TransactionType.income.rawValue
            let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines)
            try transactionRepository.insert(
                amount: amountInCents,
                type: type,
                categoryId: categoryId,
                note: noteText.isEmpty ? nil : noteText,
                tagIds: tagIds
            )
            didSave = true

            // 记录交易创建，触发评分检查
            AppReviewService.shared.recordTransactionCreated()
        } catch {
            isSaving = false
            errorMessage = L("error_save_failed")
        }
    }
}
