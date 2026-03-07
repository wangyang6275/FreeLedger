import Testing
import Foundation
import GRDB
@testable import FreeLedger

typealias Tag = FreeLedger.Tag
typealias Category = FreeLedger.Category

// MARK: - Test Helpers

private func makeCategory(id: String = "cat1", type: String = "expense") -> Category {
    Category(id: id, nameKey: "test_category", iconName: "cart", colorHex: "#FF0000", type: type, sortOrder: 0)
}

private func makeTransaction(id: String = "tx1", amount: Int64 = 1000, type: String = "expense", categoryId: String = "cat1") -> Transaction {
    Transaction(id: id, amount: amount, type: type, categoryId: categoryId, note: "test note")
}

private func makeAchievementVM() -> AchievementViewModel {
    let dbQueue = try! DatabaseQueue()
    let service = AchievementService(dbQueue: dbQueue)
    return AchievementViewModel(achievementService: service)
}

// MARK: - HomeViewModel Tests

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {
    @Test func loadDataSetsTransactionsAndSummary() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let tx = makeTransaction()
        txRepo.transactions = [tx]
        txRepo.summary = TransactionSummary(totalExpense: 1000, totalIncome: 0)
        catRepo.categoryDict = ["cat1": makeCategory()]
        setRepo.currency = "USD"

        let vm = HomeViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.isEmpty == false)
        #expect(vm.currencyCode == "USD")
        #expect(vm.summary.totalExpense == 1000)
        #expect(vm.groupedTransactions.count > 0)
        #expect(vm.errorMessage == nil)
    }

    @Test func loadDataHandlesError() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        txRepo.shouldThrow = true

        let vm = HomeViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.isEmpty == true)
        #expect(vm.errorMessage != nil)
    }

    @Test func loadDataWithEmptyTransactions() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = HomeViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.isEmpty == true)
        #expect(vm.errorMessage == nil)
    }
}

// MARK: - RecordViewModel Tests

@Suite("RecordViewModel Tests")
struct RecordViewModelTests {
    @Test func initialState() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)

        #expect(vm.amountString == "")
        #expect(vm.isExpense == true)
        #expect(vm.canSave == false)
        #expect(vm.didSave == false)
    }

    @Test func amountInCentsConversion() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "12.50"

        #expect(vm.amountInCents == 1250)
        #expect(vm.canSave == true)
    }

    @Test func loadCategoriesExpense() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let cat = makeCategory()
        catRepo.expenseCategories = [cat]

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.isExpense = true
        vm.loadCategories()

        #expect(vm.categories.count == 1)
        #expect(vm.categories.first?.id == cat.id)
    }

    @Test func loadCategoriesIncome() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let cat = makeCategory(type: "income")
        catRepo.incomeCategories = [cat]

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.isExpense = false
        vm.loadCategories()

        #expect(vm.categories.count == 1)
    }

    @Test func saveTransactionSuccess() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "25"
        vm.saveTransaction(categoryId: "cat1")

        #expect(vm.didSave == true)
        #expect(txRepo.transactions.count == 1)
        #expect(txRepo.transactions.first?.amount == 2500)
    }

    @Test func saveTransactionFailure() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        txRepo.shouldThrow = true

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "25"
        vm.saveTransaction(categoryId: "cat1")

        #expect(vm.didSave == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func saveTransactionRejectsZeroAmount() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "0"
        vm.saveTransaction(categoryId: "cat1")

        #expect(vm.didSave == false)
        #expect(txRepo.transactions.isEmpty)
    }

    @Test func toggleType() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        #expect(vm.isExpense == true)

        vm.toggleType()
        #expect(vm.isExpense == false)

        vm.toggleType()
        #expect(vm.isExpense == true)
    }
}

// MARK: - TagsViewModel Tests

@Suite("TagsViewModel Tests")
struct TagsViewModelTests {
    @Test func loadData() {
        let tagRepo = MockTagRepository()
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        tagRepo.tags = [tag]
        tagRepo.transactionCounts = [tag.id: 5]

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.loadData()

        #expect(vm.tags.count == 1)
        #expect(vm.transactionCount(for: tag) == 5)
        #expect(vm.isEmpty == false)
    }

    @Test func createTag() {
        let tagRepo = MockTagRepository()
        let vm = TagsViewModel(tagRepository: tagRepo)

        vm.createTag(name: "Travel", colorHex: "#00FF00")

        #expect(tagRepo.tags.count == 1)
        #expect(tagRepo.tags.first?.name == "Travel")
    }

    @Test func createTagRejectsEmpty() {
        let tagRepo = MockTagRepository()
        let vm = TagsViewModel(tagRepository: tagRepo)

        vm.createTag(name: "   ", colorHex: "#00FF00")

        #expect(tagRepo.tags.isEmpty)
    }

    @Test func deleteTag() {
        let tagRepo = MockTagRepository()
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        tagRepo.tags = [tag]

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.deleteTag(id: tag.id)

        #expect(tagRepo.tags.isEmpty)
    }

    @Test func loadDataError() {
        let tagRepo = MockTagRepository()
        tagRepo.shouldThrow = true

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.loadData()

        #expect(vm.errorMessage != nil)
    }

    @Test func updateTag() {
        let tagRepo = MockTagRepository()
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        tagRepo.tags = [tag]

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.updateTag(tag, name: "Groceries", colorHex: "#00FF00")

        #expect(tagRepo.tags.first?.name == "Groceries")
        #expect(tagRepo.tags.first?.colorHex == "#00FF00")
    }

    @Test func updateTagRejectsEmpty() {
        let tagRepo = MockTagRepository()
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        tagRepo.tags = [tag]

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.updateTag(tag, name: "   ", colorHex: "#00FF00")

        #expect(tagRepo.tags.first?.name == "Food") // unchanged
    }

    @Test func updateTagError() {
        let tagRepo = MockTagRepository()
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        tagRepo.tags = [tag]
        tagRepo.shouldThrow = true

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.updateTag(tag, name: "New", colorHex: "#00FF00")

        #expect(vm.errorMessage != nil)
    }

    @Test func createTagError() {
        let tagRepo = MockTagRepository()
        tagRepo.shouldThrow = true

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.createTag(name: "Test", colorHex: "#FF0000")

        #expect(vm.errorMessage != nil)
    }

    @Test func deleteTagError() {
        let tagRepo = MockTagRepository()
        tagRepo.shouldThrow = true

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.deleteTag(id: "some-id")

        #expect(vm.errorMessage != nil)
    }

    @Test func emptyState() {
        let tagRepo = MockTagRepository()
        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.loadData()

        #expect(vm.isEmpty == true)
    }

    @Test func transactionCountDefaultZero() {
        let tagRepo = MockTagRepository()
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        tagRepo.tags = [tag]

        let vm = TagsViewModel(tagRepository: tagRepo)
        vm.loadData()

        #expect(vm.transactionCount(for: tag) == 0)
    }
}

// MARK: - SearchViewModel Tests

@Suite("SearchViewModel Tests")
struct SearchViewModelTests {
    @Test func initialState() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)

        #expect(vm.searchText == "")
        #expect(vm.hasSearched == false)
        #expect(vm.isEmpty == false)
        #expect(vm.hasActiveFilters == false)
    }

    @Test func performSearchMarksAsSearched() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.performSearch()

        #expect(vm.hasSearched == true)
    }

    @Test func clearFiltersResetsState() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.searchText = "test"
        vm.performSearch()

        vm.clearFilters()

        #expect(vm.searchText == "")
        #expect(vm.hasSearched == false)
        #expect(vm.results.isEmpty)
    }

    @Test func hasActiveFiltersDetectsText() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.searchText = "food"

        #expect(vm.hasActiveFilters == true)
    }

    @Test func loadInitialDataSetsCurrencyAndCategories() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        setRepo.currency = "USD"
        let expense = makeCategory(id: "c1", type: "expense")
        let income = makeCategory(id: "c2", type: "income")
        catRepo.expenseCategories = [expense]
        catRepo.incomeCategories = [income]
        catRepo.categoryDict = ["c1": expense, "c2": income]

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadInitialData()

        #expect(vm.currencyCode == "USD")
        #expect(vm.categories.count == 2)
        #expect(vm.categoryDict.count == 2)
    }

    @Test func loadInitialDataErrorFallbackCurrency() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        setRepo.shouldThrow = true

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadInitialData()

        #expect(vm.currencyCode == "CNY")
    }

    @Test func performSearchWithResults() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        txRepo.transactions = [
            makeTransaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1"),
            makeTransaction(id: "t2", amount: 2000, type: "expense", categoryId: "c1")
        ]
        txRepo.transactions[0] = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1", note: "lunch")
        txRepo.transactions[1] = Transaction(id: "t2", amount: 2000, type: "expense", categoryId: "c1", note: "dinner")

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.searchText = "lunch"
        vm.performSearch()

        #expect(vm.hasSearched == true)
        #expect(vm.results.count == 1)
        #expect(vm.results.first?.note == "lunch")
    }

    @Test func performSearchError() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        txRepo.shouldThrow = true

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.performSearch()

        #expect(vm.errorMessage != nil)
    }

    @Test func isEmptyWhenSearchedNoResults() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.performSearch()

        #expect(vm.isEmpty == true)
    }

    @Test func isEmptyFalseBeforeSearch() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)

        #expect(vm.isEmpty == false)
    }

    @Test func hasActiveFiltersDetectsDate() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.startDate = Date()

        #expect(vm.hasActiveFilters == true)
    }

    @Test func hasActiveFiltersDetectsCategory() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.selectedCategoryId = "c1"

        #expect(vm.hasActiveFilters == true)
    }

    @Test func categoryNameForCustomCategory() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let customCat = Category(id: "c1", nameKey: "MyCustom", iconName: "star", colorHex: "#FF0000", type: "expense", sortOrder: 0, isCustom: true)
        catRepo.categoryDict = ["c1": customCat]

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadInitialData()

        #expect(vm.categoryName(for: "c1") == "MyCustom")
    }

    @Test func categoryNameForMissingCategory() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)

        #expect(vm.categoryName(for: "nonexistent") == "—")
    }

    @Test func performSearchWithDateFilters() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.startDate = Date()
        vm.endDate = Date()
        vm.performSearch()

        #expect(vm.hasSearched == true)
    }

    @Test func performSearchWithCategoryFilter() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = SearchViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.selectedCategoryId = "c1"
        vm.performSearch()

        #expect(vm.hasSearched == true)
    }
}

// MARK: - TransactionDetailViewModel Tests

@Suite("TransactionDetailViewModel Tests")
struct TransactionDetailViewModelTests {
    @Test func loadDataSetsCurrency() {
        let tx = makeTransaction()
        let cat = makeCategory()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()
        setRepo.currency = "USD"

        let vm = TransactionDetailViewModel(
            transaction: tx, category: cat,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.loadData()

        #expect(vm.currencyCode == "USD")
    }

    @Test func deleteTransactionSuccess() {
        let tx = makeTransaction()
        let txRepo = MockTransactionRepository()
        txRepo.transactions = [tx]
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.deleteTransaction()

        #expect(vm.didDelete == true)
        #expect(txRepo.transactions.isEmpty)
    }

    @Test func deleteTransactionFailure() {
        let tx = makeTransaction()
        let txRepo = MockTransactionRepository()
        txRepo.shouldThrow = true
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.deleteTransaction()

        #expect(vm.didDelete == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func isExpenseProperty() {
        let tx = makeTransaction(type: "expense")
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        #expect(vm.isExpense == true)
    }

    @Test func isIncomeProperty() {
        let tx = makeTransaction(type: "income")
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        #expect(vm.isExpense == false)
    }

    @Test func categoryNameWithCategory() {
        let tx = makeTransaction()
        let cat = makeCategory()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: cat,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        #expect(vm.categoryName != "—")
    }

    @Test func categoryNameWithoutCategory() {
        let tx = makeTransaction()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        #expect(vm.categoryName == "—")
    }

    @Test func startEditingSetsFields() {
        let tx = makeTransaction(amount: 12345, type: "expense")
        let cat = makeCategory()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [cat]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: cat,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()

        #expect(vm.isEditing == true)
        #expect(vm.editAmountString == "123.45")
        #expect(vm.editCategoryId == tx.categoryId)
        #expect(vm.editIsExpense == true)
        #expect(vm.allCategories.count == 1)
    }

    @Test func startEditingWholeAmount() {
        let tx = makeTransaction(amount: 10000, type: "expense")
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [makeCategory()]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()

        #expect(vm.editAmountString == "100")
    }

    @Test func cancelEditing() {
        let tx = makeTransaction()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [makeCategory()]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()
        #expect(vm.isEditing == true)
        vm.cancelEditing()
        #expect(vm.isEditing == false)
    }

    @Test func saveEditSuccess() {
        let tx = makeTransaction(amount: 1000, type: "expense")
        let txRepo = MockTransactionRepository()
        txRepo.transactions = [tx]
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [makeCategory()]
        catRepo.categoryDict = ["cat1": makeCategory()]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: makeCategory(),
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()
        vm.editAmountString = "25.50"
        vm.editNote = "Updated note"
        vm.saveEdit()

        #expect(vm.isEditing == false)
        #expect(vm.transaction.amount == 2550)
        #expect(vm.transaction.note == "Updated note")
        #expect(vm.errorMessage == nil)
    }

    @Test func saveEditInvalidAmount() {
        let tx = makeTransaction()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [makeCategory()]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()
        vm.editAmountString = ""
        vm.saveEdit()

        #expect(vm.errorMessage != nil)
        #expect(vm.isEditing == true) // stays in editing mode
    }

    @Test func saveEditError() {
        let tx = makeTransaction()
        let txRepo = MockTransactionRepository()
        txRepo.shouldThrow = true
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [makeCategory()]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()
        vm.editAmountString = "10"
        vm.saveEdit()

        #expect(vm.errorMessage != nil)
    }

    @Test func saveEditEmptyNote() {
        let tx = makeTransaction(amount: 1000)
        let txRepo = MockTransactionRepository()
        txRepo.transactions = [tx]
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [makeCategory()]
        catRepo.categoryDict = ["cat1": makeCategory()]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: makeCategory(),
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()
        vm.editAmountString = "10"
        vm.editNote = "   "
        vm.saveEdit()

        #expect(vm.transaction.note == nil)
    }

    @Test func toggleEditType() {
        let tx = makeTransaction(type: "expense")
        let incomeCat = makeCategory(id: "inc1", type: "income")
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [makeCategory()]
        catRepo.incomeCategories = [incomeCat]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()
        #expect(vm.editIsExpense == true)

        vm.toggleEditType()
        #expect(vm.editIsExpense == false)
        #expect(vm.allCategories.first?.id == "inc1")
        #expect(vm.editCategoryId == "inc1")
    }

    @Test func toggleEditTypeError() {
        let tx = makeTransaction(type: "expense")
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        catRepo.expenseCategories = [makeCategory()]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()
        catRepo.shouldThrow = true
        vm.toggleEditType()

        #expect(vm.allCategories.isEmpty)
    }

    @Test func loadDataCurrencyFallback() {
        let tx = makeTransaction()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        setRepo.shouldThrow = true
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.loadData()

        #expect(vm.currencyCode == "CNY")
    }

    @Test func loadDataTagsError() {
        let tx = makeTransaction()
        let txRepo = MockTransactionRepository()
        txRepo.shouldThrow = true
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.loadData()

        #expect(vm.tags.isEmpty)
    }

    @Test func formattedAmountWorks() {
        let tx = makeTransaction(amount: 12345)
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        #expect(!vm.formattedAmount.isEmpty)
    }

    @Test func startEditingWithIncomeTransaction() {
        let tx = makeTransaction(type: "income")
        let incomeCat = makeCategory(id: "inc1", type: "income")
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        catRepo.incomeCategories = [incomeCat]
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: incomeCat,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()

        #expect(vm.editIsExpense == false)
        #expect(vm.allCategories.count == 1)
        #expect(vm.allCategories.first?.id == "inc1")
    }

    @Test func formattedDateToday() {
        let todayISO = AppDateFormatter.isoNow()
        let tx = Transaction(amount: 1000, type: "expense", categoryId: "cat1", createdAt: todayISO)
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        let result = vm.formattedDate
        #expect(!result.isEmpty)
        // Should contain today's localized label
        #expect(result.contains(L("date_today")))
    }

    @Test func formattedDateYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayISO = AppDateFormatter.formatISO(yesterday)
        let tx = Transaction(amount: 1000, type: "expense", categoryId: "cat1", createdAt: yesterdayISO)
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        let result = vm.formattedDate
        #expect(!result.isEmpty)
        #expect(result.contains(L("date_yesterday")))
    }

    @Test func formattedDateOlderDate() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let oldISO = AppDateFormatter.formatISO(oldDate)
        let tx = Transaction(amount: 1000, type: "expense", categoryId: "cat1", createdAt: oldISO)
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        let result = vm.formattedDate
        #expect(!result.isEmpty)
        // Should NOT contain today/yesterday labels
        #expect(!result.contains(L("date_today")))
        #expect(!result.contains(L("date_yesterday")))
    }

    @Test func formattedDateInvalidISO() {
        var tx = makeTransaction()
        tx.createdAt = "not-a-date"
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )

        #expect(vm.formattedDate == "")
    }

    @Test func startEditingError() {
        let tx = makeTransaction(type: "expense")
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        catRepo.shouldThrow = true
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = TransactionDetailViewModel(
            transaction: tx, category: nil,
            transactionRepository: txRepo, categoryRepository: catRepo,
            settingsRepository: setRepo, tagRepository: tagRepo
        )
        vm.startEditing()

        #expect(vm.isEditing == true)
        #expect(vm.allCategories.isEmpty)
    }
}

// MARK: - ReportViewModel Tests

@Suite("ReportViewModel Tests")
struct ReportViewModelTests {
    @Test func monthNavigation() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        let initialMonth = vm.currentMonth
        let initialYear = vm.currentYear

        vm.previousMonth()

        if initialMonth == 1 {
            #expect(vm.currentMonth == 12)
            #expect(vm.currentYear == initialYear - 1)
        } else {
            #expect(vm.currentMonth == initialMonth - 1)
            #expect(vm.currentYear == initialYear)
        }
    }

    @Test func loadDataError() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()
        txRepo.shouldThrow = true

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.loadData()

        #expect(vm.errorMessage != nil)
    }

    @Test func emptyState() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.loadData()

        #expect(vm.isEmpty == true)
    }

    @Test func loadDataSetsSummaryAndCurrency() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()
        setRepo.currency = "USD"
        txRepo.summary = TransactionSummary(totalExpense: 50000, totalIncome: 80000)
        txRepo.categoryBreakdown = [CategoryBreakdown(categoryId: "cat1", categoryName: "Food", iconName: "cart", colorHex: "#FF0000", total: 50000, percentage: 100.0)]
        txRepo.monthlyTrends = [MonthlyTrend(year: 2025, month: 1, monthLabel: "Jan", expense: 50000, income: 80000)]
        tagRepo.tagBreakdown = [TagExpenseBreakdown(tagId: "t1", tagName: "Lunch", colorHex: "#00FF00", total: 20000)]

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.loadData()

        #expect(vm.currencyCode == "USD")
        #expect(vm.isEmpty == false)
        #expect(vm.summary.totalExpense == 50000)
        #expect(vm.expenseBreakdown.count == 1)
        #expect(vm.trendData.count == 1)
        #expect(vm.tagBreakdown.count == 1)
    }

    @Test func nextMonthNavigation() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        let initialMonth = vm.currentMonth
        let initialYear = vm.currentYear

        vm.nextMonth()

        if initialMonth == 12 {
            #expect(vm.currentMonth == 1)
            #expect(vm.currentYear == initialYear + 1)
        } else {
            #expect(vm.currentMonth == initialMonth + 1)
            #expect(vm.currentYear == initialYear)
        }
    }

    @Test func selectCategory() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)

        vm.selectCategory("cat1")
        #expect(vm.selectedCategoryId == "cat1")

        // Toggle off
        vm.selectCategory("cat1")
        #expect(vm.selectedCategoryId == nil)

        // Select different
        vm.selectCategory("cat2")
        #expect(vm.selectedCategoryId == "cat2")
    }

    @Test func monthTitleNotEmpty() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        #expect(!vm.monthTitle.isEmpty)
    }

    @Test func navigationResetsSelectedCategory() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.selectCategory("cat1")
        #expect(vm.selectedCategoryId == "cat1")

        vm.previousMonth()
        #expect(vm.selectedCategoryId == nil)
    }

    @Test func loadDataCurrencyFallback() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()
        setRepo.shouldThrow = true

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.loadData()

        #expect(vm.currencyCode == "CNY")
    }

    @Test func previousMonthJanuaryWrapsToDecember() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.currentMonth = 1
        vm.currentYear = 2026

        vm.previousMonth()

        #expect(vm.currentMonth == 12)
        #expect(vm.currentYear == 2025)
        #expect(vm.selectedCategoryId == nil)
    }

    @Test func nextMonthDecemberWrapsToJanuary() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.currentMonth = 12
        vm.currentYear = 2025

        vm.nextMonth()

        #expect(vm.currentMonth == 1)
        #expect(vm.currentYear == 2026)
        #expect(vm.selectedCategoryId == nil)
    }

    @Test func previousMonthNormalCase() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.currentMonth = 6
        vm.currentYear = 2026

        vm.previousMonth()

        #expect(vm.currentMonth == 5)
        #expect(vm.currentYear == 2026)
    }

    @Test func nextMonthNormalCase() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        let tagRepo = MockTagRepository()

        let vm = ReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo, tagRepository: tagRepo)
        vm.currentMonth = 6
        vm.currentYear = 2026

        vm.nextMonth()

        #expect(vm.currentMonth == 7)
        #expect(vm.currentYear == 2026)
    }
}

// MARK: - TransactionSummary Tests

@Suite("TransactionSummary Tests")
struct TransactionSummaryTests {
    @Test func balanceCalculation() {
        let summary = TransactionSummary(totalExpense: 5000, totalIncome: 8000)
        #expect(summary.balance == 3000)
    }

    @Test func emptyState() {
        let summary = TransactionSummary.empty
        #expect(summary.totalExpense == 0)
        #expect(summary.totalIncome == 0)
        #expect(summary.balance == 0)
    }

    @Test func negativeBalance() {
        let summary = TransactionSummary(totalExpense: 10000, totalIncome: 3000)
        #expect(summary.balance == -7000)
    }
}

// MARK: - AmountFormatter Tests

@Suite("AmountFormatter Tests")
struct AmountFormatterTests {
    @Test func toCentsInteger() {
        let cents = AmountFormatter.toCents("25")
        #expect(cents == 2500)
    }

    @Test func toCentsDecimal() {
        let cents = AmountFormatter.toCents("12.50")
        #expect(cents == 1250)
    }

    @Test func toCentsEmpty() {
        let cents = AmountFormatter.toCents("")
        #expect(cents == 0)
    }
}

// MARK: - TemplateViewModel Tests

@Suite("TemplateViewModel Tests")
struct TemplateViewModelTests {
    @Test func loadDataSetsItems() {
        let templateRepo = MockTransactionTemplateRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let template = TransactionTemplate(title: "Coffee", amount: 500, categoryId: "cat1")
        templateRepo.templates = [template]
        catRepo.categoryDict = ["cat1": makeCategory()]
        setRepo.currency = "USD"

        let vm = TemplateViewModel(templateRepository: templateRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.items.count == 1)
        #expect(vm.items.first?.template.title == "Coffee")
        #expect(vm.items.first?.category?.id == "cat1")
        #expect(vm.currencyCode == "USD")
    }

    @Test func loadDataEmpty() {
        let templateRepo = MockTransactionTemplateRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = TemplateViewModel(templateRepository: templateRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.items.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    @Test func loadDataError() {
        let templateRepo = MockTransactionTemplateRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        templateRepo.shouldThrow = true

        let vm = TemplateViewModel(templateRepository: templateRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.errorMessage != nil)
    }

    @Test func addTemplate() {
        let templateRepo = MockTransactionTemplateRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        catRepo.categoryDict = ["cat1": makeCategory()]

        let vm = TemplateViewModel(templateRepository: templateRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.addTemplate(title: "Lunch", amount: 1500, type: "expense", categoryId: "cat1", note: "Daily lunch")

        #expect(templateRepo.templates.count == 1)
        #expect(templateRepo.templates.first?.title == "Lunch")
        #expect(templateRepo.templates.first?.amount == 1500)
    }

    @Test func addTemplateError() {
        let templateRepo = MockTransactionTemplateRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        templateRepo.shouldThrow = true

        let vm = TemplateViewModel(templateRepository: templateRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.addTemplate(title: "Test", amount: 100, type: "expense", categoryId: "cat1", note: nil)

        #expect(vm.errorMessage != nil)
    }

    @Test func deleteTemplate() {
        let templateRepo = MockTransactionTemplateRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let template = TransactionTemplate(title: "Coffee", amount: 500, categoryId: "cat1")
        templateRepo.templates = [template]

        let vm = TemplateViewModel(templateRepository: templateRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.deleteTemplate(id: template.id)

        #expect(templateRepo.templates.isEmpty)
    }

    @Test func deleteTemplateError() {
        let templateRepo = MockTransactionTemplateRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        templateRepo.shouldThrow = true

        let vm = TemplateViewModel(templateRepository: templateRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.deleteTemplate(id: "some-id")

        #expect(vm.errorMessage != nil)
    }
}

// MARK: - AnnualReportViewModel Tests

@Suite("AnnualReportViewModel Tests")
struct AnnualReportViewModelTests {
    @Test func initialState() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()

        let vm = AnnualReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo)

        let currentYear = Calendar.current.component(.year, from: Date())
        #expect(vm.currentYear == currentYear)
        #expect(vm.isEmpty == true)
        #expect(vm.netAmount == 0)
    }

    @Test func loadDataSetsSummary() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        setRepo.currency = "USD"
        txRepo.summary = TransactionSummary(totalExpense: 50000, totalIncome: 80000)
        txRepo.monthlyTrends = [
            MonthlyTrend(year: 2025, month: 1, monthLabel: "Jan", expense: 20000, income: 30000),
            MonthlyTrend(year: 2025, month: 2, monthLabel: "Feb", expense: 30000, income: 50000),
        ]

        let vm = AnnualReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.isEmpty == false)
        #expect(vm.currencyCode == "USD")
        #expect(vm.summary.totalExpense == 50000)
        #expect(vm.summary.totalIncome == 80000)
        #expect(vm.netAmount == 30000)
        #expect(vm.monthlySummaries.count == 2)
    }

    @Test func avgMonthlyCalculations() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        txRepo.summary = TransactionSummary(totalExpense: 60000, totalIncome: 90000)
        txRepo.monthlyTrends = [
            MonthlyTrend(year: 2025, month: 1, monthLabel: "Jan", expense: 20000, income: 30000),
            MonthlyTrend(year: 2025, month: 2, monthLabel: "Feb", expense: 40000, income: 60000),
            MonthlyTrend(year: 2025, month: 3, monthLabel: "Mar", expense: 0, income: 0),
        ]

        let vm = AnnualReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.avgMonthlyExpense == 30000) // 60000 / 2 active months
        #expect(vm.avgMonthlyIncome == 45000) // 90000 / 2 active months
    }

    @Test func highestLowestExpenseMonth() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        txRepo.summary = TransactionSummary(totalExpense: 60000, totalIncome: 0)
        txRepo.monthlyTrends = [
            MonthlyTrend(year: 2025, month: 1, monthLabel: "Jan", expense: 10000, income: 0),
            MonthlyTrend(year: 2025, month: 2, monthLabel: "Feb", expense: 50000, income: 0),
            MonthlyTrend(year: 2025, month: 3, monthLabel: "Mar", expense: 0, income: 0),
        ]

        let vm = AnnualReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.highestExpenseMonth?.month == 2)
        #expect(vm.lowestExpenseMonth?.month == 1)
    }

    @Test func yearNavigation() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()

        let vm = AnnualReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo)
        let initial = vm.currentYear

        vm.previousYear()
        #expect(vm.currentYear == initial - 1)

        vm.nextYear()
        vm.nextYear()
        #expect(vm.currentYear == initial + 1)
    }

    @Test func loadDataError() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()
        txRepo.shouldThrow = true

        let vm = AnnualReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.errorMessage != nil)
    }

    @Test func emptyDataAvgReturnsZero() {
        let txRepo = MockTransactionRepository()
        let setRepo = MockSettingsRepository()

        let vm = AnnualReportViewModel(transactionRepository: txRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.avgMonthlyExpense == 0)
        #expect(vm.avgMonthlyIncome == 0)
        #expect(vm.highestExpenseMonth == nil)
        #expect(vm.lowestExpenseMonth == nil)
    }
}

// MARK: - Achievement Model Tests

@Suite("Achievement Model Tests")
struct AchievementModelTests {
    @Test func allAchievementsCount() {
        #expect(Achievement.allAchievements.count == 16)
    }

    @Test func achievementCategoriesPresent() {
        let categories = Set(Achievement.allAchievements.map(\.category))
        #expect(categories.contains(.recording))
        #expect(categories.contains(.streak))
        #expect(categories.contains(.budget))
        #expect(categories.contains(.exploration))
    }

    @Test func uniqueIds() {
        let ids = Achievement.allAchievements.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test func allStartUnlocked() {
        for achievement in Achievement.allAchievements {
            #expect(achievement.isUnlocked == false)
            #expect(achievement.unlockedAt == nil)
        }
    }

    @Test func recordingCategory() {
        let recording = Achievement.allAchievements.filter { $0.category == .recording }
        #expect(recording.count == 6) // 1, 10, 50, 100, 500, 1000
        #expect(recording.first?.threshold == 1)
    }

    @Test func streakCategory() {
        let streak = Achievement.allAchievements.filter { $0.category == .streak }
        #expect(streak.count == 5) // 3, 7, 30, 100, 365
    }

    @Test func budgetCategory() {
        let budget = Achievement.allAchievements.filter { $0.category == .budget }
        #expect(budget.count == 2) // set, under_3
    }

    @Test func explorationCategory() {
        let exploration = Achievement.allAchievements.filter { $0.category == .exploration }
        #expect(exploration.count == 3) // tag, export, template
    }

    @Test func allHaveTitleAndDescKeys() {
        for achievement in Achievement.allAchievements {
            #expect(achievement.titleKey.hasPrefix("achievement_"))
            #expect(achievement.descriptionKey.hasPrefix("achievement_"))
            #expect(achievement.descriptionKey.hasSuffix("_desc"))
        }
    }

    @Test func allHaveIconNames() {
        for achievement in Achievement.allAchievements {
            #expect(!achievement.iconName.isEmpty)
        }
    }

    @Test func thresholdsPositive() {
        for achievement in Achievement.allAchievements {
            #expect(achievement.threshold > 0)
        }
    }
}

// MARK: - AchievementCategory Tests

@Suite("AchievementCategory Tests")
struct AchievementCategoryTests {
    @Test func rawValues() {
        #expect(AchievementCategory.recording.rawValue == "recording")
        #expect(AchievementCategory.streak.rawValue == "streak")
        #expect(AchievementCategory.budget.rawValue == "budget")
        #expect(AchievementCategory.exploration.rawValue == "exploration")
    }
}

// MARK: - TransactionTemplate Model Tests

@Suite("TransactionTemplate Model Tests")
struct TransactionTemplateModelTests {
    @Test func defaultValues() {
        let template = TransactionTemplate(title: "Coffee", amount: 500, categoryId: "cat1")
        #expect(!template.id.isEmpty)
        #expect(template.title == "Coffee")
        #expect(template.amount == 500)
        #expect(template.type == TransactionType.expense.rawValue)
        #expect(template.categoryId == "cat1")
        #expect(template.note == nil)
        #expect(template.sortOrder == 0)
        #expect(!template.createdAt.isEmpty)
    }

    @Test func customValues() {
        let template = TransactionTemplate(
            title: "Salary", amount: 1000000, type: "income",
            categoryId: "salary", note: "Monthly", sortOrder: 5
        )
        #expect(template.title == "Salary")
        #expect(template.amount == 1000000)
        #expect(template.type == "income")
        #expect(template.note == "Monthly")
        #expect(template.sortOrder == 5)
    }

    @Test func uniqueIds() {
        let t1 = TransactionTemplate(title: "A", amount: 100, categoryId: "c1")
        let t2 = TransactionTemplate(title: "B", amount: 200, categoryId: "c2")
        #expect(t1.id != t2.id)
    }
}

// MARK: - BudgetViewModel Tests

@Suite("BudgetViewModel Tests")
struct BudgetViewModelTests {
    @Test func loadDataSetsOverallBudget() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        budgetRepo.overallBudget = Budget(amount: 100000)
        txRepo.summary = TransactionSummary(totalExpense: 30000, totalIncome: 0)
        setRepo.currency = "USD"

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.overallBudget != nil)
        #expect(vm.overallBudget?.amount == 100000)
        #expect(vm.overallSpent == 30000)
        #expect(vm.currencyCode == "USD")
        #expect(vm.errorMessage == nil)
    }

    @Test func overallPercentageCalculation() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        budgetRepo.overallBudget = Budget(amount: 100000)
        txRepo.summary = TransactionSummary(totalExpense: 50000, totalIncome: 0)

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.overallPercentage == 50.0)
        #expect(vm.overallRemaining == 50000)
        #expect(vm.isOverallOverBudget == false)
    }

    @Test func overBudgetDetection() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        budgetRepo.overallBudget = Budget(amount: 10000)
        txRepo.summary = TransactionSummary(totalExpense: 20000, totalIncome: 0)

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.isOverallOverBudget == true)
        #expect(vm.overallRemaining == 0)
        #expect(vm.overallPercentage == 100.0) // capped at 100
    }

    @Test func noBudgetReturnsZeroPercentage() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.overallBudget == nil)
        #expect(vm.overallPercentage == 0)
        #expect(vm.overallRemaining == 0)
        #expect(vm.isOverallOverBudget == false)
    }

    @Test func setOverallBudget() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.setOverallBudget(amount: 50000)

        #expect(budgetRepo.overallBudget?.amount == 50000)
    }

    @Test func setOverallBudgetError() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        budgetRepo.shouldThrow = true

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.setOverallBudget(amount: 50000)

        #expect(vm.errorMessage != nil)
    }

    @Test func deleteOverallBudget() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let budget = Budget(amount: 100000)
        budgetRepo.overallBudget = budget

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()
        vm.deleteOverallBudget()

        #expect(budgetRepo.overallBudget == nil)
    }

    @Test func setCategoryBudget() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.setCategoryBudget(categoryId: "cat1", amount: 20000)

        #expect(budgetRepo.categoryBudgets.count == 1)
        #expect(budgetRepo.categoryBudgets.first?.categoryId == "cat1")
        #expect(budgetRepo.categoryBudgets.first?.amount == 20000)
    }

    @Test func deleteCategoryBudget() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let budget = Budget(amount: 20000, categoryId: "cat1")
        budgetRepo.categoryBudgets = [budget]

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.deleteCategoryBudget(id: budget.id)

        #expect(budgetRepo.categoryBudgets.isEmpty)
    }

    @Test func categoryBudgetItems() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let cat = makeCategory(id: "cat1")
        let budget = Budget(amount: 50000, categoryId: "cat1")
        budgetRepo.categoryBudgets = [budget]
        catRepo.categoryDict = ["cat1": cat]
        txRepo.categoryBreakdown = [CategoryBreakdown(categoryId: "cat1", categoryName: "test", iconName: "cart", colorHex: "#FF0000", total: 30000, percentage: 100.0)]

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.categoryBudgetItems.count == 1)
        #expect(vm.categoryBudgetItems.first?.spent == 30000)
        #expect(vm.categoryBudgetItems.first?.remaining == 20000)
        #expect(vm.categoryBudgetItems.first?.isOverBudget == false)
    }

    @Test func availableCategoriesExcludesBudgeted() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let cat1 = makeCategory(id: "cat1")
        let cat2 = makeCategory(id: "cat2")
        let budget = Budget(amount: 50000, categoryId: "cat1")
        budgetRepo.categoryBudgets = [budget]
        catRepo.categoryDict = ["cat1": cat1, "cat2": cat2]
        catRepo.expenseCategories = [cat1, cat2]

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        let available = vm.availableCategories()
        #expect(available.count == 1)
        #expect(available.first?.id == "cat2")
    }

    @Test func loadDataError() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        setRepo.shouldThrow = true

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.errorMessage != nil)
    }

    @Test func deleteOverallBudgetError() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let budget = Budget(amount: 100000)
        budgetRepo.overallBudget = budget

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()
        budgetRepo.shouldThrow = true
        vm.deleteOverallBudget()

        #expect(vm.errorMessage != nil)
    }

    @Test func setCategoryBudgetError() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        budgetRepo.shouldThrow = true

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.setCategoryBudget(categoryId: "cat1", amount: 20000)

        #expect(vm.errorMessage != nil)
    }

    @Test func deleteCategoryBudgetError() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let budget = Budget(amount: 20000, categoryId: "cat1")
        budgetRepo.categoryBudgets = [budget]

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        budgetRepo.shouldThrow = true
        vm.deleteCategoryBudget(id: budget.id)

        #expect(vm.errorMessage != nil)
    }

    @Test func deleteOverallBudgetNoOpWhenNil() {
        let budgetRepo = MockBudgetRepository()
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = BudgetViewModel(budgetRepository: budgetRepo, transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()
        // overallBudget is nil, deleteOverallBudget should be no-op
        vm.deleteOverallBudget()

        #expect(vm.errorMessage == nil)
    }
}

// MARK: - RemindersViewModel Tests

@Suite("RemindersViewModel Tests")
struct RemindersViewModelTests {
    @Test func loadDataSetsReminders() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let reminder = Reminder(title: "Rent", amount: 500000)
        reminderRepo.reminders = [reminder]
        setRepo.currency = "USD"
        catRepo.expenseCategories = [makeCategory()]

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.reminders.count == 1)
        #expect(vm.reminders.first?.title == "Rent")
        #expect(vm.currencyCode == "USD")
        #expect(vm.isEmpty == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func emptyState() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.isEmpty == true)
    }

    @Test func createReminder() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        let reminder = Reminder(title: "Groceries", amount: 30000)
        vm.createReminder(reminder)

        #expect(reminderRepo.reminders.count == 1)
        #expect(reminderRepo.reminders.first?.title == "Groceries")
    }

    @Test func createReminderError() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        reminderRepo.shouldThrow = true

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        let reminder = Reminder(title: "Test", amount: 1000)
        vm.createReminder(reminder)

        #expect(vm.errorMessage != nil)
    }

    @Test func updateReminder() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        var reminder = Reminder(title: "Rent", amount: 500000)
        reminderRepo.reminders = [reminder]

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        reminder.title = "Updated Rent"
        vm.updateReminder(reminder)

        #expect(reminderRepo.reminders.first?.title == "Updated Rent")
    }

    @Test func deleteReminder() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let reminder = Reminder(title: "Rent", amount: 500000)
        reminderRepo.reminders = [reminder]

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.deleteReminder(id: reminder.id)

        #expect(reminderRepo.reminders.isEmpty)
    }

    @Test func deleteReminderError() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        reminderRepo.shouldThrow = true

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.deleteReminder(id: "some-id")

        #expect(vm.errorMessage != nil)
    }

    @Test func toggleEnabled() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let reminder = Reminder(title: "Rent", amount: 500000, isEnabled: true)
        reminderRepo.reminders = [reminder]

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.toggleEnabled(reminder)

        #expect(reminderRepo.reminders.first?.isEnabled == false)
    }

    @Test func categoryForId() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let cat = makeCategory(id: "cat1")
        catRepo.expenseCategories = [cat]

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.category(for: "cat1")?.id == "cat1")
        #expect(vm.category(for: "nonexistent") == nil)
        #expect(vm.category(for: nil) == nil)
    }

    @Test func loadDataError() {
        let reminderRepo = MockReminderRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        reminderRepo.shouldThrow = true

        let vm = RemindersViewModel(reminderRepository: reminderRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.errorMessage != nil)
    }
}

// MARK: - CategoryManagementViewModel Tests

@Suite("CategoryManagementViewModel Tests")
struct CategoryManagementViewModelTests {
    @Test func loadDataSetsCategories() {
        let catRepo = MockCategoryRepository()
        let expenseCat = makeCategory(id: "e1", type: "expense")
        let incomeCat = makeCategory(id: "i1", type: "income")
        catRepo.expenseCategories = [expenseCat]
        catRepo.incomeCategories = [incomeCat]

        let vm = CategoryManagementViewModel(categoryRepository: catRepo)
        vm.loadData()

        #expect(vm.expenseCategories.count == 1)
        #expect(vm.incomeCategories.count == 1)
        #expect(vm.errorMessage == nil)
    }

    @Test func currentCategoriesFollowsTab() {
        let catRepo = MockCategoryRepository()
        let expenseCat = makeCategory(id: "e1", type: "expense")
        let incomeCat = makeCategory(id: "i1", type: "income")
        catRepo.expenseCategories = [expenseCat]
        catRepo.incomeCategories = [incomeCat]

        let vm = CategoryManagementViewModel(categoryRepository: catRepo)
        vm.loadData()

        vm.isExpenseTab = true
        #expect(vm.currentCategories.count == 1)
        #expect(vm.currentCategories.first?.id == "e1")

        vm.isExpenseTab = false
        #expect(vm.currentCategories.count == 1)
        #expect(vm.currentCategories.first?.id == "i1")
    }

    @Test func deactivateCategory() {
        let catRepo = MockCategoryRepository()
        let cat = makeCategory(id: "e1")
        catRepo.expenseCategories = [cat]

        let vm = CategoryManagementViewModel(categoryRepository: catRepo)
        vm.deleteTarget = cat
        vm.deactivateCategory()

        #expect(vm.deleteTarget == nil)
    }

    @Test func deactivateCategoryError() {
        let catRepo = MockCategoryRepository()
        catRepo.shouldThrow = true
        let cat = makeCategory(id: "e1")

        let vm = CategoryManagementViewModel(categoryRepository: catRepo)
        vm.deleteTarget = cat
        vm.deactivateCategory()

        #expect(vm.errorMessage != nil)
        #expect(vm.deleteTarget == nil)
    }

    @Test func deactivateWithNoTarget() {
        let catRepo = MockCategoryRepository()
        let vm = CategoryManagementViewModel(categoryRepository: catRepo)
        vm.deleteTarget = nil
        vm.deactivateCategory()

        #expect(vm.errorMessage == nil)
    }

    @Test func categoryDisplayNameCustom() {
        let catRepo = MockCategoryRepository()
        let vm = CategoryManagementViewModel(categoryRepository: catRepo)

        let customCat = Category(id: "c1", nameKey: "My Custom", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, isCustom: true)
        #expect(vm.categoryDisplayName(customCat) == "My Custom")
    }

    @Test func loadDataError() {
        let catRepo = MockCategoryRepository()
        catRepo.shouldThrow = true

        let vm = CategoryManagementViewModel(categoryRepository: catRepo)
        vm.loadData()

        #expect(vm.errorMessage != nil)
    }
}

// MARK: - TagDetailViewModel Tests

@Suite("TagDetailViewModel Tests")
struct TagDetailViewModelTests {
    @Test func loadDataSetsTransactionsAndCurrency() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        setRepo.currency = "USD"
        catRepo.categoryDict = ["cat1": makeCategory()]

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.currencyCode == "USD")
        #expect(vm.errorMessage == nil)
    }

    @Test func totalExpenseCalculation() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.transactions = [
            makeTransaction(id: "t1", amount: 1000, type: "expense"),
            makeTransaction(id: "t2", amount: 2000, type: "expense"),
            makeTransaction(id: "t3", amount: 5000, type: "income"),
        ]

        #expect(vm.totalExpense == 3000)
        #expect(vm.totalIncome == 5000)
    }

    @Test func emptyTransactions() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)

        #expect(vm.totalExpense == 0)
        #expect(vm.totalIncome == 0)
        #expect(vm.groupedTransactions.isEmpty)
    }

    @Test func loadDataError() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        tagRepo.shouldThrow = true

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.errorMessage != nil)
    }

    @Test func loadDataCurrencyFallback() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        setRepo.shouldThrow = true

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.currencyCode == "CNY") // 降级到默认值
    }
}

// MARK: - AchievementViewModel Tests

@Suite("AchievementViewModel Tests")
struct AchievementViewModelTests {
    @Test func progressCalculation() {
        let vm = makeAchievementVM()
        var a1 = Achievement.allAchievements[0]
        a1.isUnlocked = true
        var a2 = Achievement.allAchievements[1]
        a2.isUnlocked = false
        vm.achievements = [a1, a2]

        #expect(vm.unlockedCount == 1)
        #expect(vm.totalCount == 2)
        #expect(vm.progress == 0.5)
    }

    @Test func progressZeroWhenEmpty() {
        let vm = makeAchievementVM()
        vm.achievements = []

        #expect(vm.progress == 0)
        #expect(vm.unlockedCount == 0)
        #expect(vm.totalCount == 0)
    }

    @Test func dismissCongrats() {
        let vm = makeAchievementVM()
        vm.showCongrats = true
        vm.newlyUnlocked = [Achievement.allAchievements[0]]

        vm.dismissCongrats()

        #expect(vm.showCongrats == false)
        #expect(vm.newlyUnlocked.isEmpty)
    }

    @Test func initialState() {
        let vm = makeAchievementVM()

        #expect(vm.achievements.isEmpty)
        #expect(vm.newlyUnlocked.isEmpty)
        #expect(vm.showCongrats == false)
    }
}

// MARK: - CategoryBudgetItem Tests

@Suite("CategoryBudgetItem Tests")
struct CategoryBudgetItemTests {
    @Test func percentageCalculation() {
        let item = CategoryBudgetItem(
            id: "b1",
            category: makeCategory(),
            budget: Budget(amount: 10000),
            spent: 5000
        )
        #expect(item.percentage == 50.0)
        #expect(item.remaining == 5000)
        #expect(item.isOverBudget == false)
    }

    @Test func overBudget() {
        let item = CategoryBudgetItem(
            id: "b1",
            category: makeCategory(),
            budget: Budget(amount: 10000),
            spent: 15000
        )
        #expect(item.percentage == 100.0) // capped
        #expect(item.remaining == 0)
        #expect(item.isOverBudget == true)
    }

    @Test func zeroBudgetAmount() {
        let item = CategoryBudgetItem(
            id: "b1",
            category: makeCategory(),
            budget: Budget(amount: 0),
            spent: 0
        )
        #expect(item.percentage == 0)
    }
}

// MARK: - RecordViewModel Extended Tests

@Suite("RecordViewModel Extended Tests")
struct RecordViewModelExtendedTests {
    @Test func loadCurrencySetsSymbol() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        setRepo.currency = "USD"

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadCurrency()

        // 货币符号可能因 locale 不同而不同（"$" 或 "US$"）
        #expect(vm.currencySymbol != "¥")
        #expect(!vm.currencySymbol.isEmpty)
    }

    @Test func loadCurrencyFallback() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        setRepo.shouldThrow = true

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadCurrency()

        #expect(vm.currencySymbol == "¥")
    }

    @Test func displayAmountWhenEmpty() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = ""

        #expect(vm.displayAmount == "¥ 0.00")
    }

    @Test func displayAmountWithValue() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "42.50"

        #expect(vm.displayAmount == "¥ 42.50")
    }

    @Test func displayAmountWithCustomCurrency() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.currencySymbol = "$"
        vm.amountString = "10"

        #expect(vm.displayAmount == "$ 10")
    }

    @Test func loadCategoriesError() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        catRepo.shouldThrow = true

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadCategories()

        #expect(vm.categories.isEmpty)
    }

    @Test func saveTransactionWithTags() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "15"
        vm.saveTransaction(categoryId: "cat1", tagIds: ["tag1", "tag2"])

        #expect(vm.didSave == true)
        #expect(txRepo.transactions.count == 1)
    }

    @Test func saveTransactionWithNote() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "20"
        vm.note = "Lunch"
        vm.saveTransaction(categoryId: "cat1")

        #expect(vm.didSave == true)
        #expect(txRepo.transactions.first?.note == "Lunch")
    }

    @Test func saveTransactionTrimsWhitespaceNote() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "20"
        vm.note = "   "
        vm.saveTransaction(categoryId: "cat1")

        #expect(vm.didSave == true)
        #expect(txRepo.transactions.first?.note == nil)
    }

    @Test func saveTransactionIncomeType() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "100"
        vm.isExpense = false
        vm.saveTransaction(categoryId: "cat1")

        #expect(vm.didSave == true)
        #expect(txRepo.transactions.first?.type == TransactionType.income.rawValue)
    }

    @Test func amountInCentsWithInvalidString() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "abc"

        #expect(vm.amountInCents == 0)
        #expect(vm.canSave == false)
    }
}

// MARK: - AchievementViewModel Extended Tests

@Suite("AchievementViewModel Extended Tests")
struct AchievementViewModelExtendedTests {
    @Test func loadDataWithNoAchievements() {
        let vm = makeAchievementVM()
        vm.loadData()

        #expect(vm.achievements.count == Achievement.allAchievements.count)
        #expect(vm.showCongrats == false)
        #expect(vm.newlyUnlocked.isEmpty)
    }

    @Test func progressAllUnlocked() {
        let vm = makeAchievementVM()
        vm.achievements = Achievement.allAchievements.map { a in
            var unlocked = a
            unlocked.isUnlocked = true
            return unlocked
        }

        #expect(vm.unlockedCount == Achievement.allAchievements.count)
        #expect(vm.progress == 1.0)
    }

    @Test func progressPartiallyUnlocked() {
        let vm = makeAchievementVM()
        let total = Achievement.allAchievements.count
        vm.achievements = Achievement.allAchievements.enumerated().map { idx, a in
            var m = a
            m.isUnlocked = (idx < 4)
            return m
        }

        #expect(vm.unlockedCount == 4)
        #expect(vm.totalCount == total)
        #expect(vm.progress == Double(4) / Double(total))
    }
}

// MARK: - TagDetailViewModel Extended Tests

@Suite("TagDetailViewModel Extended Tests")
struct TagDetailViewModelExtendedTests {
    @Test func groupedTransactionsWithTodayDate() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let todayISO = ISO8601DateFormatter().string(from: Date())
        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1", note: "lunch", createdAt: todayISO)
        tagRepo.tagTransactions = [tx]

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(!vm.groupedTransactions.isEmpty)
        #expect(vm.groupedTransactions.first?.1.count == 1)
    }

    @Test func groupedTransactionsMultipleDates() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let todayISO = ISO8601DateFormatter().string(from: Date())
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let oldISO = ISO8601DateFormatter().string(from: oldDate)

        tagRepo.tagTransactions = [
            Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1", createdAt: todayISO),
            Transaction(id: "t2", amount: 2000, type: "expense", categoryId: "cat1", createdAt: oldISO),
        ]

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.groupedTransactions.count == 2)
    }

    @Test func loadDataSetsCategoryDict() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let cat = makeCategory(id: "cat1")
        catRepo.categoryDict = ["cat1": cat]

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.loadData()

        #expect(vm.categoryDict["cat1"]?.id == "cat1")
    }

    @Test func totalExpenseIgnoresIncome() {
        let tag = Tag(name: "Food", colorHex: "#FF0000")
        let tagRepo = MockTagRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = TagDetailViewModel(tag: tag, tagRepository: tagRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.transactions = [
            makeTransaction(id: "t1", amount: 3000, type: "income"),
        ]

        #expect(vm.totalExpense == 0)
        #expect(vm.totalIncome == 3000)
    }
}

// MARK: - RecordViewModel Additional Tests

@Suite("RecordViewModel Additional Tests")
struct RecordViewModelAdditionalTests {
    @Test func toggleTypeLoadsNewCategories() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        let incomeCat = makeCategory(id: "inc1", type: "income")
        catRepo.incomeCategories = [incomeCat]

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.toggleType()

        #expect(vm.isExpense == false)
        #expect(vm.categories.count == 1)
        #expect(vm.categories.first?.id == "inc1")
    }

    @Test func saveTransactionSetsIsSaving() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "50"
        vm.saveTransaction(categoryId: "cat1")

        // 成功后 isSaving 保持 true，didSave 标记为 true
        #expect(vm.didSave == true)
        #expect(vm.isSaving == true)
    }

    @Test func saveTransactionErrorResetsIsSaving() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()
        txRepo.shouldThrow = true

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        vm.amountString = "50"
        vm.saveTransaction(categoryId: "cat1")

        #expect(vm.isSaving == false)
        #expect(vm.didSave == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func isNoteExpandedToggle() {
        let txRepo = MockTransactionRepository()
        let catRepo = MockCategoryRepository()
        let setRepo = MockSettingsRepository()

        let vm = RecordViewModel(transactionRepository: txRepo, categoryRepository: catRepo, settingsRepository: setRepo)
        #expect(vm.isNoteExpanded == false)

        vm.isNoteExpanded = true
        #expect(vm.isNoteExpanded == true)
    }
}

// MARK: - AchievementViewModel Additional Tests

@Suite("AchievementViewModel Additional Tests")
struct AchievementViewModelAdditionalTests {
    @Test func loadDataSetsAchievements() {
        let vm = makeAchievementVM()
        vm.loadData()

        #expect(!vm.achievements.isEmpty)
        #expect(vm.totalCount == Achievement.allAchievements.count)
    }
}

// MARK: - AmountFormatter Additional Tests

@Suite("AmountFormatter Additional Tests")
struct AmountFormatterAdditionalTests {
    @Test func formatWithDefaultLocale() {
        let result = AmountFormatter.format(2550)
        #expect(!result.isEmpty)
    }

    @Test func formatZeroWithCurrency() {
        let result = AmountFormatter.format(0)
        #expect(!result.isEmpty)
    }

    @Test func toCentsRoundingPrecision() {
        // 0.1 + 0.2 问题
        let cents = AmountFormatter.toCents("0.10")
        #expect(cents == 10)
    }

    @Test func formatDisplayPreservesInput() {
        let result = AmountFormatter.formatDisplay("123.45", currencySymbol: "€")
        #expect(result == "€ 123.45")
    }
}
