import Testing
import Foundation
import GRDB
@testable import ColorFuLedger

typealias AppTag = ColorFuLedger.Tag
typealias AppCategory = ColorFuLedger.Category

/// 创建内存数据库并执行迁移
private func makeTestDatabase() throws -> AppDatabase {
    let dbQueue = try DatabaseQueue()
    return try AppDatabase(dbQueue: dbQueue)
}

// MARK: - CategoryDAO Tests

@Suite("CategoryDAO Integration Tests")
struct CategoryDAOIntegrationTests {
    @Test func insertAndGetAll() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try dao.insert(cat)

        let all = try dao.getAll()
        #expect(all.count == 1)
        #expect(all.first?.nameKey == "food")
    }

    @Test func getByType() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)

        let expense = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        let income = AppCategory(id: "c2", nameKey: "salary", iconName: "dollar", colorHex: "#00FF00", type: "income", sortOrder: 0)
        try dao.insert(expense)
        try dao.insert(income)

        let expenses = try dao.getByType("expense")
        let incomes = try dao.getByType("income")
        #expect(expenses.count == 1)
        #expect(incomes.count == 1)
        #expect(expenses.first?.nameKey == "food")
    }

    @Test func getByTypeSortedByUsage() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)

        let cat1 = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, usageCount: 5)
        let cat2 = AppCategory(id: "c2", nameKey: "transport", iconName: "car", colorHex: "#0000FF", type: "expense", sortOrder: 1, usageCount: 10)
        try dao.insert(cat1)
        try dao.insert(cat2)

        let sorted = try dao.getByType("expense", sortedByUsage: true)
        #expect(sorted.first?.nameKey == "transport")
    }

    @Test func getAllAsDict() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try dao.insert(cat)

        let dict = try dao.getAllAsDict()
        #expect(dict["c1"]?.nameKey == "food")
    }

    @Test func updateCategory() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)

        var cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try dao.insert(cat)

        cat.nameKey = "drinks"
        try dao.update(cat)

        let fetched = try dao.getById("c1")
        #expect(fetched?.nameKey == "drinks")
    }

    @Test func deactivateCategory() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try dao.insert(cat)

        try dao.deactivate(id: "c1")

        // getByType 只返回活跃的分类
        let active = try dao.getByType("expense")
        #expect(active.isEmpty)
    }

    @Test func getNextSortOrder() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)

        let order1 = try dao.getNextSortOrder(type: "expense")
        #expect(order1 == 1)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 5)
        try dao.insert(cat)

        let order2 = try dao.getNextSortOrder(type: "expense")
        #expect(order2 == 6)
    }

    @Test func incrementUsageCount() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, usageCount: 0)
        try dao.insert(cat)

        try dao.incrementUsageCount(id: "c1")
        try dao.incrementUsageCount(id: "c1")

        let fetched = try dao.getById("c1")
        #expect(fetched?.usageCount == 2)
    }
}

// MARK: - TransactionDAO Tests

@Suite("TransactionDAO Integration Tests")
struct TransactionDAOIntegrationTests {
    private func seedCategory(dao: CategoryDAO) throws {
        let cat = AppCategory(id: "cat1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try dao.insert(cat)
    }

    private func seedIncomeCategory(dao: CategoryDAO) throws {
        let cat = AppCategory(id: "inc1", nameKey: "salary", iconName: "dollar", colorHex: "#00FF00", type: "income", sortOrder: 0)
        try dao.insert(cat)
    }

    @Test func insertAndGetAll() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let tx = Transaction(id: "t1", amount: 2500, type: "expense", categoryId: "cat1", note: "lunch")
        try dao.insert(tx)

        let all = try dao.getAll()
        #expect(all.count == 1)
        #expect(all.first?.amount == 2500)
        #expect(all.first?.note == "lunch")
    }

    @Test func getById() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1")
        try dao.insert(tx)

        let fetched = try dao.getById("t1")
        #expect(fetched != nil)
        #expect(fetched?.id == "t1")

        let missing = try dao.getById("nonexistent")
        #expect(missing == nil)
    }

    @Test func updateTransaction() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        var tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1")
        try dao.insert(tx)

        tx.amount = 5000
        tx.note = "updated"
        try dao.update(tx)

        let fetched = try dao.getById("t1")
        #expect(fetched?.amount == 5000)
        #expect(fetched?.note == "updated")
    }

    @Test func deleteTransaction() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1")
        try dao.insert(tx)

        try dao.delete(id: "t1")
        let all = try dao.getAll()
        #expect(all.isEmpty)
    }

    @Test func getByMonth() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)

        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1")
        try dao.insert(tx)

        let results = try dao.getByMonth(year: year, month: month)
        #expect(results.count == 1)

        let noResults = try dao.getByMonth(year: 2020, month: 1)
        #expect(noResults.isEmpty)
    }

    @Test func getSummary() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let incomeCat = AppCategory(id: "inc1", nameKey: "salary", iconName: "dollar", colorHex: "#00FF00", type: "income", sortOrder: 0)
        try catDAO.insert(incomeCat)

        let tx1 = Transaction(id: "t1", amount: 3000, type: "expense", categoryId: "cat1")
        let tx2 = Transaction(id: "t2", amount: 5000, type: "income", categoryId: "inc1")
        try dao.insert(tx1)
        try dao.insert(tx2)

        let cal = Calendar.current
        let startDate = cal.date(byAdding: .hour, value: -1, to: Date())!
        let endDate = cal.date(byAdding: .hour, value: 1, to: Date())!
        let startISO = AppDateFormatter.formatISO(startDate)
        let endISO = AppDateFormatter.formatISO(endDate)

        let summary = try dao.getSummary(startISO: startISO, endISO: endISO)
        #expect(summary.expense == 3000)
        #expect(summary.income == 5000)
    }

    @Test func search() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let tx1 = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1", note: "lunch at restaurant")
        let tx2 = Transaction(id: "t2", amount: 2000, type: "expense", categoryId: "cat1", note: "dinner")
        try dao.insert(tx1)
        try dao.insert(tx2)

        let results = try dao.search(keyword: "lunch", startDate: nil, endDate: nil, categoryId: nil)
        #expect(results.count == 1)
        #expect(results.first?.id == "t1")

        let all = try dao.search(keyword: nil, startDate: nil, endDate: nil, categoryId: nil)
        #expect(all.count == 2)
    }

    @Test func searchWithCategoryFilter() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let cat2 = AppCategory(id: "cat2", nameKey: "transport", iconName: "car", colorHex: "#0000FF", type: "expense", sortOrder: 1)
        try catDAO.insert(cat2)

        let tx1 = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1")
        let tx2 = Transaction(id: "t2", amount: 2000, type: "expense", categoryId: "cat2")
        try dao.insert(tx1)
        try dao.insert(tx2)

        let results = try dao.search(keyword: nil, startDate: nil, endDate: nil, categoryId: "cat1")
        #expect(results.count == 1)
        #expect(results.first?.categoryId == "cat1")
    }

    @Test func getCategoryBreakdown() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)

        let tx1 = Transaction(id: "t1", amount: 3000, type: "expense", categoryId: "cat1")
        let tx2 = Transaction(id: "t2", amount: 2000, type: "expense", categoryId: "cat1")
        try dao.insert(tx1)
        try dao.insert(tx2)

        let breakdown = try dao.getCategoryBreakdown(year: year, month: month, type: "expense")
        #expect(breakdown.count == 1)
        #expect(breakdown.first?.total == 5000)
    }

    @Test func getByYear() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)

        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1")
        try dao.insert(tx)

        let results = try dao.getByYear(year: year)
        #expect(results.count == 1)

        let noResults = try dao.getByYear(year: 2000)
        #expect(noResults.isEmpty)
    }

    @Test func getCategoryBreakdownForYear() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let cat2 = AppCategory(id: "cat2", nameKey: "transport", iconName: "car", colorHex: "#0000FF", type: "expense", sortOrder: 1)
        try catDAO.insert(cat2)

        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)

        let tx1 = Transaction(id: "t1", amount: 3000, type: "expense", categoryId: "cat1")
        let tx2 = Transaction(id: "t2", amount: 2000, type: "expense", categoryId: "cat2")
        try dao.insert(tx1)
        try dao.insert(tx2)

        let breakdown = try dao.getCategoryBreakdownForYear(year: year, type: "expense")
        #expect(breakdown.count == 2)
        // 按 total DESC 排序
        #expect(breakdown.first?.total == 3000)
        #expect(breakdown.last?.total == 2000)

        let emptyBreakdown = try dao.getCategoryBreakdownForYear(year: 2000, type: "expense")
        #expect(emptyBreakdown.isEmpty)
    }

    @Test func getMonthlyTrends() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)
        try seedIncomeCategory(dao: catDAO)

        let tx1 = Transaction(id: "t1", amount: 3000, type: "expense", categoryId: "cat1")
        let tx2 = Transaction(id: "t2", amount: 5000, type: "income", categoryId: "inc1")
        try dao.insert(tx1)
        try dao.insert(tx2)

        let cal = Calendar.current
        let startDate = cal.date(byAdding: .hour, value: -1, to: Date())!
        let endDate = cal.date(byAdding: .hour, value: 1, to: Date())!

        let trends = try dao.getMonthlyTrends(
            startISO: AppDateFormatter.formatISO(startDate),
            endISO: AppDateFormatter.formatISO(endDate)
        )
        #expect(trends.count == 1)
        #expect(trends.first?.expense == 3000)
        #expect(trends.first?.income == 5000)
    }

    @Test func searchWithDateFilter() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionDAO(dbQueue: appDb.dbQueue)
        try seedCategory(dao: catDAO)

        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "cat1", note: "test")
        try dao.insert(tx)

        let cal = Calendar.current
        let startDate = cal.date(byAdding: .hour, value: -1, to: Date())!
        let endDate = cal.date(byAdding: .hour, value: 1, to: Date())!

        let results = try dao.search(
            keyword: nil,
            startDate: AppDateFormatter.formatISO(startDate),
            endDate: AppDateFormatter.formatISO(endDate),
            categoryId: nil
        )
        #expect(results.count == 1)

        // 过去的日期范围应返回空
        let pastStart = cal.date(byAdding: .year, value: -2, to: Date())!
        let pastEnd = cal.date(byAdding: .year, value: -1, to: Date())!
        let empty = try dao.search(
            keyword: nil,
            startDate: AppDateFormatter.formatISO(pastStart),
            endDate: AppDateFormatter.formatISO(pastEnd),
            categoryId: nil
        )
        #expect(empty.isEmpty)
    }
}

// MARK: - TagDAO Tests

@Suite("TagDAO Integration Tests")
struct TagDAOIntegrationTests {
    @Test func insertAndGetAll() throws {
        let appDb = try makeTestDatabase()
        let dao = TagDAO(dbQueue: appDb.dbQueue)

        let tag = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        try dao.insert(tag)

        let all = try dao.getAll()
        #expect(all.count == 1)
        #expect(all.first?.name == "Lunch")
    }

    @Test func getById() throws {
        let appDb = try makeTestDatabase()
        let dao = TagDAO(dbQueue: appDb.dbQueue)

        let tag = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        try dao.insert(tag)

        let fetched = try dao.getById("tag1")
        #expect(fetched?.name == "Lunch")

        let missing = try dao.getById("nonexistent")
        #expect(missing == nil)
    }

    @Test func updateTag() throws {
        let appDb = try makeTestDatabase()
        let dao = TagDAO(dbQueue: appDb.dbQueue)

        var tag = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        try dao.insert(tag)

        tag.name = "Dinner"
        try dao.update(tag)

        let fetched = try dao.getById("tag1")
        #expect(fetched?.name == "Dinner")
    }

    @Test func deleteTag() throws {
        let appDb = try makeTestDatabase()
        let dao = TagDAO(dbQueue: appDb.dbQueue)

        let tag = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        try dao.insert(tag)

        try dao.delete(id: "tag1")
        let all = try dao.getAll()
        #expect(all.isEmpty)
    }

    @Test func setAndGetTagsForTransaction() throws {
        let appDb = try makeTestDatabase()
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "cat1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tx = Transaction(id: "tx1", amount: 1000, type: "expense", categoryId: "cat1")
        try txDAO.insert(tx)

        let tag1 = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        let tag2 = AppTag(id: "tag2", name: "Work", colorHex: "#0000FF")
        try tagDAO.insert(tag1)
        try tagDAO.insert(tag2)

        try appDb.dbQueue.write { db in
            try tagDAO.setTagsForTransaction(transactionId: "tx1", tagIds: ["tag1", "tag2"], in: db)
        }

        let tags = try tagDAO.getTagsForTransaction(transactionId: "tx1")
        #expect(tags.count == 2)
    }

    @Test func getTransactionCountPerTag() throws {
        let appDb = try makeTestDatabase()
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "cat1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tag = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        try tagDAO.insert(tag)

        let tx1 = Transaction(id: "tx1", amount: 1000, type: "expense", categoryId: "cat1")
        let tx2 = Transaction(id: "tx2", amount: 2000, type: "expense", categoryId: "cat1")
        try txDAO.insert(tx1)
        try txDAO.insert(tx2)

        try appDb.dbQueue.write { db in
            try tagDAO.setTagsForTransaction(transactionId: "tx1", tagIds: ["tag1"], in: db)
            try tagDAO.setTagsForTransaction(transactionId: "tx2", tagIds: ["tag1"], in: db)
        }

        let counts = try tagDAO.getTransactionCountPerTag()
        #expect(counts["tag1"] == 2)
    }

    @Test func getTransactionsForTag() throws {
        let appDb = try makeTestDatabase()
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "cat1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tag = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        try tagDAO.insert(tag)

        let tx = Transaction(id: "tx1", amount: 1000, type: "expense", categoryId: "cat1")
        try txDAO.insert(tx)

        try appDb.dbQueue.write { db in
            try tagDAO.setTagsForTransaction(transactionId: "tx1", tagIds: ["tag1"], in: db)
        }

        let transactions = try tagDAO.getTransactionsForTag(tagId: "tag1")
        #expect(transactions.count == 1)
        #expect(transactions.first?.id == "tx1")
    }

    @Test func getTagExpenseBreakdown() throws {
        let appDb = try makeTestDatabase()
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "cat1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tag1 = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        let tag2 = AppTag(id: "tag2", name: "Dinner", colorHex: "#0000FF")
        try tagDAO.insert(tag1)
        try tagDAO.insert(tag2)

        let tx1 = Transaction(id: "tx1", amount: 3000, type: "expense", categoryId: "cat1")
        let tx2 = Transaction(id: "tx2", amount: 2000, type: "expense", categoryId: "cat1")
        try txDAO.insert(tx1)
        try txDAO.insert(tx2)

        try appDb.dbQueue.write { db in
            try tagDAO.setTagsForTransaction(transactionId: "tx1", tagIds: ["tag1", "tag2"], in: db)
            try tagDAO.setTagsForTransaction(transactionId: "tx2", tagIds: ["tag1"], in: db)
        }

        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)

        let breakdown = try tagDAO.getTagExpenseBreakdown(year: year, month: month)
        #expect(breakdown.count == 2)
        // tag1 关联了两个交易 (3000+2000=5000), tag2 只有一个 (3000)
        let tag1Breakdown = breakdown.first(where: { $0.id == "tag1" })
        let tag2Breakdown = breakdown.first(where: { $0.id == "tag2" })
        #expect(tag1Breakdown?.total == 5000)
        #expect(tag2Breakdown?.total == 3000)

        // 不同月份应返回空
        let emptyBreakdown = try tagDAO.getTagExpenseBreakdown(year: 2000, month: 1)
        #expect(emptyBreakdown.isEmpty)
    }
}

// MARK: - BudgetDAO Tests

@Suite("BudgetDAO Integration Tests")
struct BudgetDAOIntegrationTests {
    @Test func upsertAndGetOverall() throws {
        let appDb = try makeTestDatabase()
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)

        try dao.upsertOverall(amount: 100000)
        let budget = try dao.getOverall()
        #expect(budget?.amount == 100000)
        #expect(budget?.isOverall == true)

        // upsert 更新已有的
        try dao.upsertOverall(amount: 200000)
        let updated = try dao.getOverall()
        #expect(updated?.amount == 200000)
    }

    @Test func upsertAndGetCategoryBudget() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        try dao.upsertCategoryBudget(categoryId: "c1", amount: 50000)
        let budget = try dao.getByCategoryId("c1")
        #expect(budget?.amount == 50000)
        #expect(budget?.categoryId == "c1")

        // upsert 更新
        try dao.upsertCategoryBudget(categoryId: "c1", amount: 80000)
        let updated = try dao.getByCategoryId("c1")
        #expect(updated?.amount == 80000)
    }

    @Test func getCategoryBudgets() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)

        let cat1 = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        let cat2 = AppCategory(id: "c2", nameKey: "transport", iconName: "car", colorHex: "#0000FF", type: "expense", sortOrder: 1)
        try catDAO.insert(cat1)
        try catDAO.insert(cat2)

        try dao.upsertOverall(amount: 100000)
        try dao.upsertCategoryBudget(categoryId: "c1", amount: 30000)
        try dao.upsertCategoryBudget(categoryId: "c2", amount: 20000)

        let catBudgets = try dao.getCategoryBudgets()
        #expect(catBudgets.count == 2)

        let all = try dao.getAll()
        #expect(all.count == 3)
    }

    @Test func deleteBudget() throws {
        let appDb = try makeTestDatabase()
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)

        try dao.upsertOverall(amount: 100000)
        let budget = try dao.getOverall()!

        try dao.delete(id: budget.id)
        let deleted = try dao.getOverall()
        #expect(deleted == nil)
    }
}

// MARK: - ReminderDAO Tests

@Suite("ReminderDAO Integration Tests")
struct ReminderDAOIntegrationTests {
    @Test func insertAndGetAll() throws {
        let appDb = try makeTestDatabase()
        let dao = ReminderDAO(dbQueue: appDb.dbQueue)

        let r = Reminder(id: "r1", title: "Pay rent", amount: 500000)
        try dao.insert(r)

        let all = try dao.getAll()
        #expect(all.count == 1)
        #expect(all.first?.title == "Pay rent")
    }

    @Test func getEnabled() throws {
        let appDb = try makeTestDatabase()
        let dao = ReminderDAO(dbQueue: appDb.dbQueue)

        let r1 = Reminder(id: "r1", title: "Enabled", amount: 1000, isEnabled: true)
        let r2 = Reminder(id: "r2", title: "Disabled", amount: 2000, isEnabled: false)
        try dao.insert(r1)
        try dao.insert(r2)

        let enabled = try dao.getEnabled()
        #expect(enabled.count == 1)
        #expect(enabled.first?.title == "Enabled")
    }

    @Test func getById() throws {
        let appDb = try makeTestDatabase()
        let dao = ReminderDAO(dbQueue: appDb.dbQueue)

        let r = Reminder(id: "r1", title: "Test", amount: 1000)
        try dao.insert(r)

        let fetched = try dao.getById("r1")
        #expect(fetched?.title == "Test")

        let missing = try dao.getById("nonexistent")
        #expect(missing == nil)
    }

    @Test func updateReminder() throws {
        let appDb = try makeTestDatabase()
        let dao = ReminderDAO(dbQueue: appDb.dbQueue)

        var r = Reminder(id: "r1", title: "Old", amount: 1000)
        try dao.insert(r)

        r.title = "New"
        r.amount = 5000
        try dao.update(r)

        let fetched = try dao.getById("r1")
        #expect(fetched?.title == "New")
        #expect(fetched?.amount == 5000)
    }

    @Test func deleteReminder() throws {
        let appDb = try makeTestDatabase()
        let dao = ReminderDAO(dbQueue: appDb.dbQueue)

        let r = Reminder(id: "r1", title: "Test", amount: 1000)
        try dao.insert(r)

        try dao.delete(id: "r1")
        let all = try dao.getAll()
        #expect(all.isEmpty)
    }
}

// MARK: - SettingsDAO Tests

@Suite("SettingsDAO Integration Tests")
struct SettingsDAOIntegrationTests {
    @Test func setAndGet() throws {
        let appDb = try makeTestDatabase()
        let dao = SettingsDAO(dbQueue: appDb.dbQueue)

        try dao.set(key: "currency", value: "USD")
        let value = try dao.get(key: "currency")
        #expect(value == "USD")
    }

    @Test func getMissing() throws {
        let appDb = try makeTestDatabase()
        let dao = SettingsDAO(dbQueue: appDb.dbQueue)

        let value = try dao.get(key: "nonexistent")
        #expect(value == nil)
    }

    @Test func overwriteSetting() throws {
        let appDb = try makeTestDatabase()
        let dao = SettingsDAO(dbQueue: appDb.dbQueue)

        try dao.set(key: "currency", value: "USD")
        try dao.set(key: "currency", value: "EUR")

        let value = try dao.get(key: "currency")
        #expect(value == "EUR")
    }
}

// MARK: - TransactionTemplateDAO Tests

@Suite("TransactionTemplateDAO Integration Tests")
struct TransactionTemplateDAOIntegrationTests {
    @Test func insertAndGetAll() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionTemplateDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let template = TransactionTemplate(id: "t1", title: "Coffee", amount: 500, categoryId: "c1")
        try dao.insert(template)

        let all = try dao.getAll()
        #expect(all.count == 1)
        #expect(all.first?.title == "Coffee")
    }

    @Test func getById() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionTemplateDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let template = TransactionTemplate(id: "t1", title: "Coffee", amount: 500, categoryId: "c1")
        try dao.insert(template)

        let fetched = try dao.getById("t1")
        #expect(fetched?.title == "Coffee")

        let missing = try dao.getById("nonexistent")
        #expect(missing == nil)
    }

    @Test func updateTemplate() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionTemplateDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        var template = TransactionTemplate(id: "t1", title: "Coffee", amount: 500, categoryId: "c1")
        try dao.insert(template)

        template.title = "Tea"
        template.amount = 300
        try dao.update(template)

        let fetched = try dao.getById("t1")
        #expect(fetched?.title == "Tea")
        #expect(fetched?.amount == 300)
    }

    @Test func deleteTemplate() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionTemplateDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let template = TransactionTemplate(id: "t1", title: "Coffee", amount: 500, categoryId: "c1")
        try dao.insert(template)

        try dao.delete(id: "t1")
        let all = try dao.getAll()
        #expect(all.isEmpty)
    }
}

// MARK: - Repository Integration Tests

@Suite("CategoryRepository Integration Tests")
struct CategoryRepositoryIntegrationTests {
    @Test func getExpenseAndIncomeCategories() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)
        let repo = CategoryRepository(dao: dao)

        let expense = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        let income = AppCategory(id: "c2", nameKey: "salary", iconName: "dollar", colorHex: "#00FF00", type: "income", sortOrder: 0)
        try dao.insert(expense)
        try dao.insert(income)

        let expenses = try repo.getExpenseCategories(sortedByUsage: false)
        let incomes = try repo.getIncomeCategories(sortedByUsage: false)
        #expect(expenses.count == 1)
        #expect(incomes.count == 1)
    }

    @Test func createAndDeactivate() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)
        let repo = CategoryRepository(dao: dao)

        let cat = AppCategory(id: "c1", nameKey: "test", iconName: "star", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try repo.create(cat)

        let before = try repo.getExpenseCategories(sortedByUsage: false)
        #expect(before.count == 1)

        try repo.deactivate(id: "c1")
        let after = try repo.getExpenseCategories(sortedByUsage: false)
        #expect(after.isEmpty)
    }

    @Test func incrementUsageAndGetDict() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)
        let repo = CategoryRepository(dao: dao)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, usageCount: 0)
        try repo.create(cat)

        try repo.incrementUsageCount(id: "c1")
        try repo.incrementUsageCount(id: "c1")

        let dict = try repo.getAllAsDict()
        #expect(dict["c1"]?.usageCount == 2)
    }

    @Test func updateAndGetNextSortOrder() throws {
        let appDb = try makeTestDatabase()
        let dao = CategoryDAO(dbQueue: appDb.dbQueue)
        let repo = CategoryRepository(dao: dao)

        var cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 3)
        try repo.create(cat)

        cat.nameKey = "updated"
        try repo.update(cat)
        let dict = try repo.getAllAsDict()
        #expect(dict["c1"]?.nameKey == "updated")

        let nextOrder = try repo.getNextSortOrder(type: "expense")
        #expect(nextOrder == 4)
    }
}

@Suite("SettingsRepository Integration Tests")
struct SettingsRepositoryIntegrationTests {
    @Test func getAndSetCurrency() throws {
        let appDb = try makeTestDatabase()
        let dao = SettingsDAO(dbQueue: appDb.dbQueue)
        let repo = SettingsRepository(dao: dao)

        // 默认返回 CNY
        let defaultCurrency = try repo.getCurrency()
        #expect(defaultCurrency == "CNY")

        try repo.setCurrency("USD")
        let updated = try repo.getCurrency()
        #expect(updated == "USD")
    }

    @Test func getAndSetGeneric() throws {
        let appDb = try makeTestDatabase()
        let dao = SettingsDAO(dbQueue: appDb.dbQueue)
        let repo = SettingsRepository(dao: dao)

        let missing = try repo.get(key: "theme")
        #expect(missing == nil)

        try repo.set(key: "theme", value: "dark")
        let value = try repo.get(key: "theme")
        #expect(value == "dark")
    }
}

@Suite("BudgetRepository Integration Tests")
struct BudgetRepositoryIntegrationTests {
    @Test func overallBudgetCRUD() throws {
        let appDb = try makeTestDatabase()
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)
        let repo = BudgetRepository(dao: dao)

        #expect(try repo.getOverallBudget() == nil)

        try repo.setOverallBudget(amount: 100000)
        let budget = try repo.getOverallBudget()
        #expect(budget?.amount == 100000)
    }

    @Test func categoryBudgetCRUD() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)
        let repo = BudgetRepository(dao: dao)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        try repo.setCategoryBudget(categoryId: "c1", amount: 30000)
        let budget = try repo.getBudgetForCategory("c1")
        #expect(budget?.amount == 30000)

        let all = try repo.getCategoryBudgets()
        #expect(all.count == 1)
    }

    @Test func deleteBudget() throws {
        let appDb = try makeTestDatabase()
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)
        let repo = BudgetRepository(dao: dao)

        try repo.setOverallBudget(amount: 100000)
        let budget = try repo.getOverallBudget()!
        try repo.deleteBudget(id: budget.id)

        #expect(try repo.getOverallBudget() == nil)
    }
}

@Suite("ReminderRepository Integration Tests")
struct ReminderRepositoryIntegrationTests {
    @Test func crudOperations() throws {
        let appDb = try makeTestDatabase()
        let dao = ReminderDAO(dbQueue: appDb.dbQueue)
        let repo = ReminderRepository(dao: dao)

        let r = Reminder(id: "r1", title: "Test", amount: 1000)
        try repo.create(r)

        let all = try repo.getAll()
        #expect(all.count == 1)

        let fetched = try repo.getById("r1")
        #expect(fetched?.title == "Test")

        let enabled = try repo.getEnabled()
        #expect(enabled.count == 1)

        var updated = r
        updated.title = "Updated"
        try repo.update(updated)

        let refetched = try repo.getById("r1")
        #expect(refetched?.title == "Updated")

        try repo.delete(id: "r1")
        #expect(try repo.getAll().isEmpty)
    }
}

@Suite("TransactionTemplateRepository Integration Tests")
struct TransactionTemplateRepositoryIntegrationTests {
    @Test func crudOperations() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let dao = TransactionTemplateDAO(dbQueue: appDb.dbQueue)
        let repo = TransactionTemplateRepository(dao: dao)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let template = TransactionTemplate(id: "t1", title: "Coffee", amount: 500, categoryId: "c1")
        try repo.insert(template)

        let all = try repo.getAll()
        #expect(all.count == 1)

        let fetched = try repo.getById("t1")
        #expect(fetched?.title == "Coffee")

        var updated = template
        updated.title = "Tea"
        try repo.update(updated)
        #expect(try repo.getById("t1")?.title == "Tea")

        try repo.delete(id: "t1")
        #expect(try repo.getAll().isEmpty)
    }
}

// MARK: - TransactionRepository Integration Tests

@Suite("TransactionRepository Integration Tests")
struct TransactionRepositoryIntegrationTests {
    private func makeRepo(_ appDb: AppDatabase) -> (TransactionRepository, CategoryDAO, TagDAO) {
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)
        let repo = TransactionRepository(dbQueue: appDb.dbQueue, transactionDAO: txDAO, categoryDAO: catDAO, tagDAO: tagDAO)
        return (repo, catDAO, tagDAO)
    }

    private func seedCategories(_ catDAO: CategoryDAO) throws {
        let expense = AppCategory(id: "cat1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, isCustom: true)
        let income = AppCategory(id: "inc1", nameKey: "salary", iconName: "dollar", colorHex: "#00FF00", type: "income", sortOrder: 0)
        try catDAO.insert(expense)
        try catDAO.insert(income)
    }

    @Test func insertAndGetAll() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 2500, type: "expense", categoryId: "cat1", note: "lunch", tagIds: [])
        let all = try repo.getAll()
        #expect(all.count == 1)
        #expect(all.first?.amount == 2500)
    }

    @Test func insertWithTagsIncrementsCategoryUsage() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, tagDAO) = makeRepo(appDb)
        try seedCategories(catDAO)

        let tag = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        try tagDAO.insert(tag)

        try repo.insert(amount: 1000, type: "expense", categoryId: "cat1", note: nil, tagIds: ["tag1"])

        // 验证 category usage_count 被递增
        let cat = try catDAO.getById("cat1")
        #expect(cat?.usageCount == 1)

        // 验证 tag 关联
        let all = try repo.getAll()
        let tags = try repo.getTagsForTransaction(transactionId: all.first!.id)
        #expect(tags.count == 1)
        #expect(tags.first?.id == "tag1")
    }

    @Test func getByIdAndUpdate() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 1000, type: "expense", categoryId: "cat1", note: "test")
        let all = try repo.getAll()
        let txId = all.first!.id

        let fetched = try repo.getById(txId)
        #expect(fetched != nil)

        var tx = fetched!
        tx.amount = 5000
        try repo.update(tx)

        let updated = try repo.getById(txId)
        #expect(updated?.amount == 5000)
    }

    @Test func deleteTransaction() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 1000, type: "expense", categoryId: "cat1", note: nil)
        let all = try repo.getAll()
        try repo.delete(id: all.first!.id)
        #expect(try repo.getAll().isEmpty)
    }

    @Test func getTransactionsForMonth() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 1000, type: "expense", categoryId: "cat1", note: nil)
        let cal = Calendar.current
        let now = Date()
        let results = try repo.getTransactionsForMonth(year: cal.component(.year, from: now), month: cal.component(.month, from: now))
        #expect(results.count == 1)

        let empty = try repo.getTransactionsForMonth(year: 2000, month: 1)
        #expect(empty.isEmpty)
    }

    @Test func getMonthlySummary() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 3000, type: "expense", categoryId: "cat1", note: nil)
        try repo.insert(amount: 5000, type: "income", categoryId: "inc1", note: nil)

        let cal = Calendar.current
        let now = Date()
        let summary = try repo.getMonthlySummary(year: cal.component(.year, from: now), month: cal.component(.month, from: now))
        #expect(summary.totalExpense == 3000)
        #expect(summary.totalIncome == 5000)
    }

    @Test func setAndGetTagsForTransaction() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, tagDAO) = makeRepo(appDb)
        try seedCategories(catDAO)

        let tag1 = AppTag(id: "tag1", name: "A", colorHex: "#FF0000")
        let tag2 = AppTag(id: "tag2", name: "B", colorHex: "#0000FF")
        try tagDAO.insert(tag1)
        try tagDAO.insert(tag2)

        try repo.insert(amount: 1000, type: "expense", categoryId: "cat1", note: nil, tagIds: ["tag1"])
        let txId = try repo.getAll().first!.id

        // 重新设置 tags
        try repo.setTagsForTransaction(transactionId: txId, tagIds: ["tag1", "tag2"])
        let tags = try repo.getTagsForTransaction(transactionId: txId)
        #expect(tags.count == 2)
    }

    @Test func searchKeyword() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 1000, type: "expense", categoryId: "cat1", note: "coffee")
        try repo.insert(amount: 2000, type: "expense", categoryId: "cat1", note: "dinner")

        let results = try repo.search(keyword: "coffee", startDate: nil, endDate: nil, categoryId: nil, limit: 100)
        #expect(results.count == 1)
        #expect(results.first?.note == "coffee")
    }

    @Test func getCategoryBreakdown() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        let cat2 = AppCategory(id: "cat2", nameKey: "transport", iconName: "car", colorHex: "#0000FF", type: "expense", sortOrder: 1, isCustom: false)
        try catDAO.insert(cat2)

        try repo.insert(amount: 3000, type: "expense", categoryId: "cat1", note: nil)
        try repo.insert(amount: 2000, type: "expense", categoryId: "cat2", note: nil)

        let cal = Calendar.current
        let now = Date()
        let breakdown = try repo.getCategoryBreakdown(year: cal.component(.year, from: now), month: cal.component(.month, from: now), type: "expense")
        #expect(breakdown.count == 2)
        // 自定义分类直接使用 nameKey
        let cat1Breakdown = breakdown.first(where: { $0.categoryId == "cat1" })
        #expect(cat1Breakdown?.categoryName == "food")
        // 百分比合计
        let totalPct = breakdown.reduce(0.0) { $0 + $1.percentage }
        #expect(abs(totalPct - 100.0) < 0.01)
    }

    @Test func getLast6MonthsSummary() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 1000, type: "expense", categoryId: "cat1", note: nil)

        let cal = Calendar.current
        let now = Date()
        let results = try repo.getLast6MonthsSummary(
            fromYear: cal.component(.year, from: now),
            fromMonth: cal.component(.month, from: now)
        )
        #expect(results.count == 6)
        // 当月应有数据
        let currentMonth = results.last
        #expect(currentMonth?.expense == 1000)
        // 每个月都有 monthLabel
        let allHaveLabels = results.allSatisfy { !$0.monthLabel.isEmpty }
        #expect(allHaveLabels)
    }

    @Test func getAnnualSummary() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 3000, type: "expense", categoryId: "cat1", note: nil)
        try repo.insert(amount: 8000, type: "income", categoryId: "inc1", note: nil)

        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let summary = try repo.getAnnualSummary(year: year)
        #expect(summary.totalExpense == 3000)
        #expect(summary.totalIncome == 8000)
    }

    @Test func getAnnualMonthlySummaries() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 1000, type: "expense", categoryId: "cat1", note: nil)

        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let results = try repo.getAnnualMonthlySummaries(year: year)
        #expect(results.count == 12)
        // 当月有数据
        let currentMonth = cal.component(.month, from: Date())
        let monthData = results.first(where: { $0.month == currentMonth })
        #expect(monthData?.expense == 1000)
        // 所有月份都有 label
        let allHaveLabels = results.allSatisfy { !$0.monthLabel.isEmpty }
        #expect(allHaveLabels)
    }

    @Test func getAnnualCategoryBreakdown() throws {
        let appDb = try makeTestDatabase()
        let (repo, catDAO, _) = makeRepo(appDb)
        try seedCategories(catDAO)

        try repo.insert(amount: 5000, type: "expense", categoryId: "cat1", note: nil)

        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let breakdown = try repo.getAnnualCategoryBreakdown(year: year, type: "expense")
        #expect(breakdown.count == 1)
        #expect(breakdown.first?.total == 5000)
        #expect(breakdown.first?.percentage == 100.0)
    }
}

// MARK: - TagRepository Integration Tests

@Suite("TagRepository Integration Tests")
struct TagRepositoryIntegrationTests {
    @Test func crudOperations() throws {
        let appDb = try makeTestDatabase()
        let dao = TagDAO(dbQueue: appDb.dbQueue)
        let repo = TagRepository(dao: dao)

        let tag = AppTag(id: "t1", name: "Work", colorHex: "#FF0000")
        try repo.create(tag)

        let all = try repo.getAll()
        #expect(all.count == 1)

        let fetched = try repo.getById("t1")
        #expect(fetched?.name == "Work")

        var updated = tag
        updated.name = "Personal"
        try repo.update(updated)
        #expect(try repo.getById("t1")?.name == "Personal")

        try repo.delete(id: "t1")
        #expect(try repo.getAll().isEmpty)
    }

    @Test func getTagsAndCountsForTransaction() throws {
        let appDb = try makeTestDatabase()
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)
        let repo = TagRepository(dao: tagDAO)

        let cat = AppCategory(id: "cat1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tag1 = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        let tag2 = AppTag(id: "tag2", name: "Work", colorHex: "#0000FF")
        try tagDAO.insert(tag1)
        try tagDAO.insert(tag2)

        let tx1 = Transaction(id: "tx1", amount: 1000, type: "expense", categoryId: "cat1")
        let tx2 = Transaction(id: "tx2", amount: 2000, type: "expense", categoryId: "cat1")
        try txDAO.insert(tx1)
        try txDAO.insert(tx2)

        try appDb.dbQueue.write { db in
            try tagDAO.setTagsForTransaction(transactionId: "tx1", tagIds: ["tag1", "tag2"], in: db)
            try tagDAO.setTagsForTransaction(transactionId: "tx2", tagIds: ["tag1"], in: db)
        }

        // getTagsForTransaction
        let tags = try repo.getTagsForTransaction(transactionId: "tx1")
        #expect(tags.count == 2)

        // getTransactionCountPerTag
        let counts = try repo.getTransactionCountPerTag()
        #expect(counts["tag1"] == 2)
        #expect(counts["tag2"] == 1)

        // getTransactionsForTag
        let transactions = try repo.getTransactionsForTag(tagId: "tag1")
        #expect(transactions.count == 2)
    }

    @Test func getTagExpenseBreakdown() throws {
        let appDb = try makeTestDatabase()
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)
        let repo = TagRepository(dao: tagDAO)

        let cat = AppCategory(id: "cat1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tag = AppTag(id: "tag1", name: "Lunch", colorHex: "#FF0000")
        try tagDAO.insert(tag)

        let tx = Transaction(id: "tx1", amount: 4000, type: "expense", categoryId: "cat1")
        try txDAO.insert(tx)

        try appDb.dbQueue.write { db in
            try tagDAO.setTagsForTransaction(transactionId: "tx1", tagIds: ["tag1"], in: db)
        }

        let cal = Calendar.current
        let now = Date()
        let breakdown = try repo.getTagExpenseBreakdown(
            year: cal.component(.year, from: now),
            month: cal.component(.month, from: now)
        )
        #expect(breakdown.count == 1)
        #expect(breakdown.first?.total == 4000)
        #expect(breakdown.first?.tagName == "Lunch")
    }
}

// MARK: - AchievementService Integration Tests

@Suite("AchievementService Integration Tests")
struct AchievementServiceIntegrationTests {
    private func makeService() throws -> (AchievementService, AppDatabase) {
        let appDb = try makeTestDatabase()
        // 清理 UserDefaults 中的成就数据
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
        let service = AchievementService(dbQueue: appDb.dbQueue)
        return (service, appDb)
    }

    @Test func getAchievementsInitially() throws {
        let (service, _) = try makeService()
        let achievements = service.getAchievements()
        // 所有成就都未解锁
        let allLocked = achievements.allSatisfy { !$0.isUnlocked }
        #expect(allLocked)
        #expect(achievements.count > 0)
    }

    @Test func evaluateFirstRecord() throws {
        let (service, appDb) = try makeService()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1")
        try txDAO.insert(tx)

        let newlyUnlocked = service.evaluateAll()
        let hasFirstRecord = newlyUnlocked.contains(where: { $0.id == "first_record" })
        #expect(hasFirstRecord)

        // 再次 evaluate 不应重复解锁
        let again = service.evaluateAll()
        let hasFirstAgain = again.contains(where: { $0.id == "first_record" })
        #expect(!hasFirstAgain)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateFirstTag() throws {
        let (service, appDb) = try makeService()
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)

        let tag = AppTag(id: "tag1", name: "Work", colorHex: "#FF0000")
        try tagDAO.insert(tag)

        let newlyUnlocked = service.evaluateAll()
        let hasFirstTag = newlyUnlocked.contains(where: { $0.id == "first_tag" })
        #expect(hasFirstTag)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateBudgetSet() throws {
        let (service, appDb) = try makeService()
        let budgetDAO = BudgetDAO(dbQueue: appDb.dbQueue)

        try budgetDAO.upsertOverall(amount: 100000)

        let newlyUnlocked = service.evaluateAll()
        let hasBudgetSet = newlyUnlocked.contains(where: { $0.id == "budget_set" })
        #expect(hasBudgetSet)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateFirstTemplate() throws {
        let (service, appDb) = try makeService()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let templateDAO = TransactionTemplateDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let template = TransactionTemplate(id: "tmpl1", title: "Coffee", amount: 500, categoryId: "c1")
        try templateDAO.insert(template)

        let newlyUnlocked = service.evaluateAll()
        let hasTemplate = newlyUnlocked.contains(where: { $0.id == "first_template" })
        #expect(hasTemplate)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateStreak() throws {
        let (service, appDb) = try makeService()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        // 添加连续3天的交易
        let cal = Calendar.current
        for i in 0..<3 {
            let date = cal.date(byAdding: .day, value: -i, to: Date())!
            let tx = Transaction(id: "t\(i)", amount: 1000, type: "expense", categoryId: "c1", createdAt: AppDateFormatter.formatISO(date))
            try txDAO.insert(tx)
        }

        let newlyUnlocked = service.evaluateAll()
        let hasStreak3 = newlyUnlocked.contains(where: { $0.id == "streak_3" })
        #expect(hasStreak3)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateRecords10() throws {
        let (service, appDb) = try makeService()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        for i in 0..<10 {
            let tx = Transaction(id: "t\(i)", amount: Int64(1000 + i), type: "expense", categoryId: "c1")
            try txDAO.insert(tx)
        }

        let newlyUnlocked = service.evaluateAll()
        let has10 = newlyUnlocked.contains(where: { $0.id == "records_10" })
        #expect(has10)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateFirstExport() throws {
        let (service, _) = try makeService()
        UserDefaults.standard.set(true, forKey: "has_exported_data")

        let newlyUnlocked = service.evaluateAll()
        let hasExport = newlyUnlocked.contains(where: { $0.id == "first_export" })
        #expect(hasExport)

        // 清理
        UserDefaults.standard.removeObject(forKey: "has_exported_data")
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateBudgetUnder3() throws {
        let (service, appDb) = try makeService()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let budgetDAO = BudgetDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        // 设置分类预算 100000
        try budgetDAO.upsertCategoryBudget(categoryId: "c1", amount: 100000)

        // 在过去3个月内各添加一笔低于预算的支出
        let cal = Calendar.current
        for monthOffset in 1...3 {
            let date = cal.date(byAdding: .month, value: -monthOffset, to: Date())!
            let tx = Transaction(id: "t\(monthOffset)", amount: 5000, type: "expense", categoryId: "c1", createdAt: AppDateFormatter.formatISO(date))
            try txDAO.insert(tx)
        }

        let newlyUnlocked = service.evaluateAll()
        let hasUnder3 = newlyUnlocked.contains(where: { $0.id == "budget_under_3" })
        #expect(hasUnder3)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateRecords50() throws {
        let (service, appDb) = try makeService()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        for i in 0..<50 {
            let tx = Transaction(id: "t\(i)", amount: Int64(1000 + i), type: "expense", categoryId: "c1")
            try txDAO.insert(tx)
        }

        let newlyUnlocked = service.evaluateAll()
        let has50 = newlyUnlocked.contains(where: { $0.id == "records_50" })
        #expect(has50)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func evaluateStreak7() throws {
        let (service, appDb) = try makeService()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let cal = Calendar.current
        for i in 0..<7 {
            let date = cal.date(byAdding: .day, value: -i, to: Date())!
            let tx = Transaction(id: "t\(i)", amount: 1000, type: "expense", categoryId: "c1", createdAt: AppDateFormatter.formatISO(date))
            try txDAO.insert(tx)
        }

        let newlyUnlocked = service.evaluateAll()
        let hasStreak7 = newlyUnlocked.contains(where: { $0.id == "streak_7" })
        #expect(hasStreak7)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func getAchievementsAfterUnlock() throws {
        let (service, appDb) = try makeService()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "c1", nameKey: "food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1")
        try txDAO.insert(tx)

        _ = service.evaluateAll()

        let achievements = service.getAchievements()
        let firstRecord = achievements.first(where: { $0.id == "first_record" })
        #expect(firstRecord?.isUnlocked == true)
        #expect(firstRecord?.unlockedAt != nil)

        // 清理
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }
}

// MARK: - AppDatabase Integration Tests

@Suite("AppDatabase Integration Tests")
struct AppDatabaseIntegrationTests {
    @Test func inMemoryMigrationCreatesAllTables() throws {
        let appDb = try makeTestDatabase()

        try appDb.dbQueue.read { db in
            // 验证所有表都已创建
            let tables = try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
            #expect(tables.contains("categories"))
            #expect(tables.contains("transactions"))
            #expect(tables.contains("settings"))
            #expect(tables.contains("tags"))
            #expect(tables.contains("transaction_tags"))
            #expect(tables.contains("reminders"))
            #expect(tables.contains("budgets"))
            #expect(tables.contains("transaction_templates"))
        }
    }

    @Test func seedDefaultSettings() throws {
        let appDb = try makeTestDatabase()
        try appDb.seedDefaultSettings()

        let dao = SettingsDAO(dbQueue: appDb.dbQueue)
        let currency = try dao.get(key: "currency")
        #expect(currency != nil)

        // 重复调用不应覆盖
        try dao.set(key: "currency", value: "USD")
        try appDb.seedDefaultSettings()
        let unchanged = try dao.get(key: "currency")
        #expect(unchanged == "USD")
    }

    @Test func indexesCreated() throws {
        let appDb = try makeTestDatabase()

        try appDb.dbQueue.read { db in
            let indexes = try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'")
            #expect(indexes.contains("idx_transactions_created_at"))
            #expect(indexes.contains("idx_transactions_category_id"))
            #expect(indexes.contains("idx_transactions_type_created_at"))
            #expect(indexes.contains("idx_categories_type_usage"))
            #expect(indexes.contains("idx_transaction_tags_transaction_id"))
            #expect(indexes.contains("idx_transaction_tags_tag_id"))
            #expect(indexes.contains("idx_budgets_category_id"))
        }
    }

    @Test func schemaVersionRecorded() throws {
        let appDb = try makeTestDatabase()

        try appDb.dbQueue.read { db in
            let version = try Int.fetchOne(db, sql: "SELECT version FROM schema_version ORDER BY version DESC LIMIT 1")
            #expect(version == 1)
        }
    }
}

// MARK: - BudgetDAO Extended Tests

@Suite("BudgetDAO Extended Tests")
struct BudgetDAOExtendedTests {
    @Test func insertAndUpdate() throws {
        let appDb = try makeTestDatabase()
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)

        let budget = Budget(amount: 50000, categoryId: nil)
        try dao.insert(budget)

        let fetched = try dao.getOverall()
        #expect(fetched?.amount == 50000)

        var updated = fetched!
        updated.amount = 80000
        try dao.update(updated)

        let refetched = try dao.getOverall()
        #expect(refetched?.amount == 80000)
    }

    @Test func getByNonexistentCategoryId() throws {
        let appDb = try makeTestDatabase()
        let dao = BudgetDAO(dbQueue: appDb.dbQueue)

        let budget = try dao.getByCategoryId("nonexistent")
        #expect(budget == nil)
    }
}

// MARK: - TransactionRepository Category Breakdown Edge Tests

@Suite("TransactionRepository Category Breakdown Edge Tests")
struct TransactionRepositoryCategoryBreakdownEdgeTests {
    @Test func getCategoryBreakdownWithCustomCategory() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)

        // 自定义分类 — nameKey 直接作为名称
        let customCat = AppCategory(id: "custom1", nameKey: "我的自定义分类", iconName: "star", colorHex: "#FF0000", type: "expense", sortOrder: 99, isCustom: true)
        try catDAO.insert(customCat)

        let tx = Transaction(amount: 5000, type: "expense", categoryId: "custom1", createdAt: "2026-03-01T10:00:00+08:00")
        try txDAO.insert(tx)

        let repo = TransactionRepository(dbQueue: appDb.dbQueue, transactionDAO: txDAO, categoryDAO: catDAO, tagDAO: tagDAO)
        let breakdown = try repo.getCategoryBreakdown(year: 2026, month: 3, type: "expense")

        #expect(breakdown.count == 1)
        #expect(breakdown.first?.categoryName == "我的自定义分类")
        #expect(breakdown.first?.percentage == 100.0)
    }

    @Test func getCategoryBreakdownWithMissingCategory() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)

        // 先创建临时分类，插入交易后删除分类来模拟“缺失分类”
        let tempCat = AppCategory(id: "temp_cat", nameKey: "temp", iconName: "cart", colorHex: "#000000", type: "expense", sortOrder: 0)
        try catDAO.insert(tempCat)
        let tx = Transaction(amount: 3000, type: "expense", categoryId: "temp_cat", createdAt: "2026-03-01T10:00:00+08:00")
        try txDAO.insert(tx)
        // 删除分类使之“缺失”
        try appDb.dbQueue.writeWithoutTransaction { db in
            try db.execute(sql: "PRAGMA foreign_keys = OFF")
            try db.execute(sql: "DELETE FROM categories WHERE id = ?", arguments: ["temp_cat"])
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        let repo = TransactionRepository(dbQueue: appDb.dbQueue, transactionDAO: txDAO, categoryDAO: catDAO, tagDAO: tagDAO)
        let breakdown = try repo.getCategoryBreakdown(year: 2026, month: 3, type: "expense")

        #expect(breakdown.count == 1)
        #expect(breakdown.first?.categoryName == "—")
        #expect(breakdown.first?.iconName == "")
        #expect(breakdown.first?.colorHex == "#E0E0E0")
    }

    @Test func getAnnualCategoryBreakdownWithCustomCategory() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)

        let customCat = AppCategory(id: "custom2", nameKey: "年度自定义", iconName: "heart", colorHex: "#00FF00", type: "expense", sortOrder: 50, isCustom: true)
        try catDAO.insert(customCat)

        let tx = Transaction(amount: 8000, type: "expense", categoryId: "custom2", createdAt: "2026-06-15T10:00:00+08:00")
        try txDAO.insert(tx)

        let repo = TransactionRepository(dbQueue: appDb.dbQueue, transactionDAO: txDAO, categoryDAO: catDAO, tagDAO: tagDAO)
        let breakdown = try repo.getAnnualCategoryBreakdown(year: 2026, type: "expense")

        #expect(breakdown.count == 1)
        #expect(breakdown.first?.categoryName == "年度自定义")
    }

    @Test func getAnnualCategoryBreakdownWithMissingCategory() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)
        let tagDAO = TagDAO(dbQueue: appDb.dbQueue)

        let tempCat = AppCategory(id: "temp_annual", nameKey: "temp", iconName: "cart", colorHex: "#000000", type: "expense", sortOrder: 0)
        try catDAO.insert(tempCat)
        let tx = Transaction(amount: 4000, type: "expense", categoryId: "temp_annual", createdAt: "2026-06-15T10:00:00+08:00")
        try txDAO.insert(tx)
        try appDb.dbQueue.writeWithoutTransaction { db in
            try db.execute(sql: "PRAGMA foreign_keys = OFF")
            try db.execute(sql: "DELETE FROM categories WHERE id = ?", arguments: ["temp_annual"])
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        let repo = TransactionRepository(dbQueue: appDb.dbQueue, transactionDAO: txDAO, categoryDAO: catDAO, tagDAO: tagDAO)
        let breakdown = try repo.getAnnualCategoryBreakdown(year: 2026, type: "expense")

        #expect(breakdown.count == 1)
        #expect(breakdown.first?.categoryName == "—")
    }
}

// MARK: - CSVExportService Edge Tests

@Suite("CSVExportService Edge Tests")
struct CSVExportServiceEdgeTests {
    @Test func exportWithCustomCategory() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let customCat = AppCategory(id: "csv_custom", nameKey: "自定义CSV分类", iconName: "star", colorHex: "#FF0000", type: "expense", sortOrder: 0, isCustom: true)
        try catDAO.insert(customCat)

        let tx = Transaction(id: "csv_tx1", amount: 2500, type: "expense", categoryId: "csv_custom", note: "含,逗号的备注")
        try txDAO.insert(tx)

        let service = CSVExportService(dbQueue: appDb.dbQueue)
        let fields = CSVExportField.defaultFields()
        let data = try service.exportCSV(fields: fields)
        let csv = String(data: data, encoding: .utf8) ?? ""

        // 自定义分类名称应直接出现
        #expect(csv.contains("自定义CSV分类"))
        // 含逗号的备注应被转义
        #expect(csv.contains("\"含,逗号的备注\""))
    }

    @Test func exportWithMissingCategory() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let tempCat = AppCategory(id: "csv_temp", nameKey: "temp", iconName: "cart", colorHex: "#000000", type: "expense", sortOrder: 0)
        try catDAO.insert(tempCat)
        let tx = Transaction(id: "csv_tx2", amount: 1000, type: "expense", categoryId: "csv_temp")
        try txDAO.insert(tx)
        try appDb.dbQueue.writeWithoutTransaction { db in
            try db.execute(sql: "PRAGMA foreign_keys = OFF")
            try db.execute(sql: "DELETE FROM categories WHERE id = ?", arguments: ["csv_temp"])
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        let service = CSVExportService(dbQueue: appDb.dbQueue)
        let fields = CSVExportField.defaultFields()
        let data = try service.exportCSV(fields: fields)
        let csv = String(data: data, encoding: .utf8) ?? ""

        #expect(csv.contains("—"))
    }

    @Test func exportWithQuotesInNote() throws {
        let appDb = try makeTestDatabase()
        let catDAO = CategoryDAO(dbQueue: appDb.dbQueue)
        let txDAO = TransactionDAO(dbQueue: appDb.dbQueue)

        let cat = AppCategory(id: "csv_cat", nameKey: "cat_food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)
        try catDAO.insert(cat)

        let tx = Transaction(id: "csv_tx3", amount: 1500, type: "expense", categoryId: "csv_cat", note: "含\"引号\"备注")
        try txDAO.insert(tx)

        let service = CSVExportService(dbQueue: appDb.dbQueue)
        let fields = CSVExportField.defaultFields()
        let data = try service.exportCSV(fields: fields)
        let csv = String(data: data, encoding: .utf8) ?? ""

        // 引号应被正确转义为双引号
        #expect(csv.contains("\"\"引号\"\""))
    }
}
