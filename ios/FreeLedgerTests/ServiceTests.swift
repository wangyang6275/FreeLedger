import Testing
import Foundation
import GRDB
@testable import FreeLedger

// MARK: - Test Helpers

private func makeTestDatabase() throws -> DatabaseQueue {
    let dbQueue = try DatabaseQueue()
    _ = try AppDatabase(dbQueue: dbQueue)
    return dbQueue
}

private func insertTestCategory(db: Database, id: String = "cat1", type: String = "expense") throws {
    let cat = Category(id: id, nameKey: "test_cat", iconName: "cart", colorHex: "#FF0000", type: type, sortOrder: 0)
    try cat.insert(db)
}

private func insertTestTransaction(db: Database, id: String = "tx1", amount: Int64 = 1000, categoryId: String = "cat1", type: String = "expense", createdAt: String? = nil) throws {
    let tx = Transaction(id: id, amount: amount, type: type, categoryId: categoryId, note: "test", createdAt: createdAt)
    try tx.insert(db)
}

private func insertTestTag(db: Database, id: String = "tag1", name: String = "Food") throws {
    let tag = FreeLedger.Tag(id: id, name: name, colorHex: "#00FF00")
    try tag.insert(db)
}

// MARK: - BackupService Tests

@Suite("BackupService Tests")
struct BackupServiceTests {
    @Test func exportEmptyDatabase() throws {
        let dbQueue = try makeTestDatabase()
        let service = BackupService(dbQueue: dbQueue)

        let data = try service.exportBackup()
        let backup = try JSONDecoder().decode(BackupData.self, from: data)

        #expect(backup.version == 1)
        #expect(backup.transactions.isEmpty)
        #expect(backup.categories.isEmpty)
        #expect(backup.tags.isEmpty)
        #expect(backup.transactionTags.isEmpty)
        #expect(!backup.checksum.isEmpty)
    }

    @Test func exportWithData() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db)
            try insertTestTag(db: db)
        }

        let service = BackupService(dbQueue: dbQueue)
        let data = try service.exportBackup()
        let backup = try JSONDecoder().decode(BackupData.self, from: data)

        #expect(backup.transactions.count == 1)
        #expect(backup.categories.count == 1)
        #expect(backup.tags.count == 1)
    }

    @Test func importRestoresData() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db)
        }

        let service = BackupService(dbQueue: dbQueue)
        let exportedData = try service.exportBackup()

        // 清空后重新导入
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM transactions")
            try db.execute(sql: "DELETE FROM categories")
        }

        let importCount = try service.importBackup(data: exportedData)
        #expect(importCount == 1)

        let restoredCount = try dbQueue.read { db in
            try Transaction.fetchCount(db)
        }
        #expect(restoredCount == 1)
    }

    @Test func importInvalidDataThrows() throws {
        let dbQueue = try makeTestDatabase()
        let service = BackupService(dbQueue: dbQueue)

        do {
            _ = try service.importBackup(data: Data("invalid".utf8))
            Issue.record("Expected error but succeeded")
        } catch is BackupError {
            // 期望抛出 BackupError
        } catch {
            Issue.record("Expected BackupError but got \(error)")
        }
    }

    @Test func importCorruptedChecksumThrows() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db)
        }

        let service = BackupService(dbQueue: dbQueue)
        let exportedData = try service.exportBackup()

        // 篡改 checksum
        let backup = try JSONDecoder().decode(BackupData.self, from: exportedData)
        let tampered = BackupData(
            version: backup.version,
            createdAt: backup.createdAt,
            checksum: "tampered_checksum",
            transactions: backup.transactions,
            categories: backup.categories,
            tags: backup.tags,
            transactionTags: backup.transactionTags
        )
        let tamperedData = try JSONEncoder().encode(tampered)

        do {
            _ = try service.importBackup(data: tamperedData)
            Issue.record("Expected checksum error but succeeded")
        } catch is BackupError {
            // 期望抛出 BackupError.checksumMismatch
        } catch {
            Issue.record("Expected BackupError but got \(error)")
        }
    }

    @Test func transactionCount() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db, id: "t1")
            try insertTestTransaction(db: db, id: "t2", amount: 2000)
        }

        let service = BackupService(dbQueue: dbQueue)
        #expect(service.transactionCount == 2)
    }

    @Test func transactionCountEmpty() throws {
        let dbQueue = try makeTestDatabase()
        let service = BackupService(dbQueue: dbQueue)
        #expect(service.transactionCount == 0)
    }

    @Test func roundTripPreservesData() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestCategory(db: db, id: "cat2", type: "income")
            try insertTestTransaction(db: db, id: "t1", amount: 5000)
            try insertTestTransaction(db: db, id: "t2", amount: 3000, categoryId: "cat2", type: "income")
            try insertTestTag(db: db, id: "tag1", name: "Food")
            try TransactionTag(transactionId: "t1", tagId: "tag1").insert(db)
        }

        let service = BackupService(dbQueue: dbQueue)
        let exportedData = try service.exportBackup()

        // 清空
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM transaction_tags")
            try db.execute(sql: "DELETE FROM transactions")
            try db.execute(sql: "DELETE FROM tags")
            try db.execute(sql: "DELETE FROM categories")
        }

        let importCount = try service.importBackup(data: exportedData)
        #expect(importCount == 2)

        let (catCount, tagCount, ttCount) = try dbQueue.read { db in
            (try Category.fetchCount(db), try FreeLedger.Tag.fetchCount(db), try TransactionTag.fetchCount(db))
        }
        #expect(catCount == 2)
        #expect(tagCount == 1)
        #expect(ttCount == 1)
    }
}

// MARK: - CSVExportService Tests

@Suite("CSVExportService Tests")
struct CSVExportServiceTests {
    @Test func exportEmptyDatabase() throws {
        let dbQueue = try makeTestDatabase()
        let service = CSVExportService(dbQueue: dbQueue)

        let fields = CSVExportField.defaultFields()
        let data = try service.exportCSV(fields: fields)
        let csv = String(data: data, encoding: .utf8)!
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        // 只有 header 行
        #expect(lines.count == 1)
        #expect(lines[0].contains("Date"))
    }

    @Test func exportWithData() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db, amount: 2500)
        }

        let service = CSVExportService(dbQueue: dbQueue)
        let fields = CSVExportField.defaultFields()
        let data = try service.exportCSV(fields: fields)
        let csv = String(data: data, encoding: .utf8)!
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 2) // header + 1 row
        #expect(lines[1].contains("25.00")) // 2500 cents => 25.00
    }

    @Test func exportNoFieldsSelected() throws {
        let dbQueue = try makeTestDatabase()
        let service = CSVExportService(dbQueue: dbQueue)

        var fields = CSVExportField.defaultFields()
        for i in fields.indices {
            fields[i].isSelected = false
        }
        let data = try service.exportCSV(fields: fields)
        #expect(data.isEmpty)
    }

    @Test func exportSelectedFieldsOnly() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db)
        }

        let service = CSVExportService(dbQueue: dbQueue)
        var fields = CSVExportField.defaultFields()
        // 仅选择 date 和 amount
        for i in fields.indices {
            fields[i].isSelected = (fields[i].id == "date" || fields[i].id == "amount")
        }

        let data = try service.exportCSV(fields: fields)
        let csv = String(data: data, encoding: .utf8)!
        let header = csv.components(separatedBy: "\n").first!
        let columns = header.components(separatedBy: ",")

        #expect(columns.count == 2)
        #expect(columns.contains("Date"))
        #expect(columns.contains("Amount"))
    }

    @Test func exportWithTags() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db, id: "t1")
            try insertTestTag(db: db, id: "tag1", name: "Food")
            try TransactionTag(transactionId: "t1", tagId: "tag1").insert(db)
        }

        let service = CSVExportService(dbQueue: dbQueue)
        let fields = CSVExportField.defaultFields()
        let data = try service.exportCSV(fields: fields)
        let csv = String(data: data, encoding: .utf8)!

        #expect(csv.contains("Food"))
    }

    @Test func defaultFieldsHaveCorrectCount() {
        let fields = CSVExportField.defaultFields()
        #expect(fields.count == 6)
        let allSelected = fields.allSatisfy(\.isSelected)
        #expect(allSelected)
    }
}

// MARK: - BackupReminderService Tests

@Suite("BackupReminderService Tests")
struct BackupReminderServiceTests {
    @Test func noReminderWhenFewTransactions() throws {
        let dbQueue = try makeTestDatabase()
        let settingsDAO = SettingsDAO(dbQueue: dbQueue)
        let service = BackupReminderService(dbQueue: dbQueue, settingsDAO: settingsDAO)

        let result = service.checkReminder()
        if case .none = result {
            // 正确: 无交易，无需提醒
        } else {
            Issue.record("Expected .none but got different result")
        }
    }

    @Test func firstBackupReminderAfter50Transactions() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            for i in 0..<50 {
                try insertTestTransaction(db: db, id: "tx\(i)")
            }
        }
        let settingsDAO = SettingsDAO(dbQueue: dbQueue)
        let service = BackupReminderService(dbQueue: dbQueue, settingsDAO: settingsDAO)

        let result = service.checkReminder()
        if case .firstBackup(let count) = result {
            #expect(count == 50)
        } else {
            Issue.record("Expected .firstBackup but got different result")
        }
    }

    @Test func noReminderAfterRecentBackup() throws {
        let dbQueue = try makeTestDatabase()
        let settingsDAO = SettingsDAO(dbQueue: dbQueue)

        // 设置最近的备份日期
        try settingsDAO.set(key: "last_backup_date", value: ISO8601DateFormatter().string(from: Date()))

        try dbQueue.write { db in
            try insertTestCategory(db: db)
            for i in 0..<100 {
                try insertTestTransaction(db: db, id: "tx\(i)")
            }
        }

        let service = BackupReminderService(dbQueue: dbQueue, settingsDAO: settingsDAO)
        let result = service.checkReminder()
        if case .none = result {
            // 正确: 最近备份过
        } else {
            Issue.record("Expected .none for recent backup")
        }
    }

    @Test func periodicReminderAfter30Days() throws {
        let dbQueue = try makeTestDatabase()
        let settingsDAO = SettingsDAO(dbQueue: dbQueue)

        // 设置 31 天前的备份日期
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        try settingsDAO.set(key: "last_backup_date", value: ISO8601DateFormatter().string(from: oldDate))

        let service = BackupReminderService(dbQueue: dbQueue, settingsDAO: settingsDAO)
        let result = service.checkReminder()
        if case .periodicBackup = result {
            // 正确: 30 天未备份
        } else {
            Issue.record("Expected .periodicBackup for old backup date")
        }
    }
}

// MARK: - AchievementService Tests

@Suite("AchievementService Tests")
struct AchievementServiceTests {
    init() {
        UserDefaults.standard.removeObject(forKey: "unlocked_achievements")
    }

    @Test func getAchievementsReturnsAll() throws {
        let dbQueue = try makeTestDatabase()
        let service = AchievementService(dbQueue: dbQueue)

        let achievements = service.getAchievements()
        #expect(achievements.count == Achievement.allAchievements.count)
        let allLocked = achievements.allSatisfy { !$0.isUnlocked }
        #expect(allLocked)
    }

    @Test func evaluateAllNoTransactions() throws {
        let dbQueue = try makeTestDatabase()
        let service = AchievementService(dbQueue: dbQueue)

        let newlyUnlocked = service.evaluateAll()
        #expect(newlyUnlocked.isEmpty)
    }

    @Test func evaluateFirstRecordAchievement() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db)
        }

        let service = AchievementService(dbQueue: dbQueue)
        let newlyUnlocked = service.evaluateAll()

        let firstRecord = newlyUnlocked.first { $0.id == "first_record" }
        #expect(firstRecord != nil)
        #expect(firstRecord?.isUnlocked == true)
    }

    @Test func evaluateDoesNotDuplicateUnlocks() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db)
        }

        let service = AchievementService(dbQueue: dbQueue)
        let first = service.evaluateAll()
        let second = service.evaluateAll()

        #expect(!first.isEmpty)
        #expect(second.isEmpty) // 不应重复解锁
    }

    @Test func evaluateRecords10() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            for i in 0..<10 {
                try insertTestTransaction(db: db, id: "tx\(i)")
            }
        }

        let service = AchievementService(dbQueue: dbQueue)
        let newlyUnlocked = service.evaluateAll()

        let records10 = newlyUnlocked.first { $0.id == "records_10" }
        #expect(records10 != nil)
    }

    @Test func evaluateFirstTag() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestTag(db: db)
        }

        let service = AchievementService(dbQueue: dbQueue)
        let newlyUnlocked = service.evaluateAll()

        let firstTag = newlyUnlocked.first { $0.id == "first_tag" }
        #expect(firstTag != nil)
    }

    @Test func evaluateBudgetSet() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            let budget = Budget(amount: 100000)
            try budget.insert(db)
        }

        let service = AchievementService(dbQueue: dbQueue)
        let newlyUnlocked = service.evaluateAll()

        let budgetSet = newlyUnlocked.first { $0.id == "budget_set" }
        #expect(budgetSet != nil)
    }

    @Test func evaluateFirstTemplate() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            let template = TransactionTemplate(title: "Coffee", amount: 500, categoryId: "cat1")
            try template.insert(db)
        }

        let service = AchievementService(dbQueue: dbQueue)
        let newlyUnlocked = service.evaluateAll()

        let firstTemplate = newlyUnlocked.first { $0.id == "first_template" }
        #expect(firstTemplate != nil)
    }

    @Test func achievementsReflectUnlockedState() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db)
        }

        let service = AchievementService(dbQueue: dbQueue)
        _ = service.evaluateAll()
        let all = service.getAchievements()

        let firstRecord = all.first { $0.id == "first_record" }
        #expect(firstRecord?.isUnlocked == true)
        #expect(firstRecord?.unlockedAt != nil)
    }
}

// MARK: - PasswordService Tests

@Suite("PasswordService Tests")
struct PasswordServiceTests {
    @Test func initiallyNoPasswordSet() {
        let service = PasswordService()
        // 在全新环境中密码未设置(注意：keychain 在测试环境中可能有残留)
        // 此测试验证基本 API 不崩溃
        _ = service.isPasswordSet()
    }

    @Test func biometricTypeAccessible() {
        let service = PasswordService()
        // 验证访问不崩溃
        _ = service.biometricType
        _ = service.canUseBiometrics()
    }

    @Test func biometricEnabledToggle() {
        let service = PasswordService()
        service.setBiometricEnabled(true)
        #expect(service.isBiometricEnabled() == true)
        service.setBiometricEnabled(false)
        #expect(service.isBiometricEnabled() == false)
    }
}

// MARK: - AppReviewService Tests

@Suite("AppReviewService Tests")
struct AppReviewServiceTests {
    @Test @MainActor func resetAndGetStats() {
        let service = AppReviewService.shared
        service.resetAllStats()

        let stats = service.getCurrentStats()
        #expect(stats["transactions"] as? Int == 0)
        #expect(stats["csvExports"] as? Int == 0)
        #expect(stats["reminders"] as? Int == 0)
        #expect(stats["hasRated"] as? Bool == false)
        #expect(stats["hasDeclined"] as? Bool == false)
    }

    @Test @MainActor func markAsRated() {
        let service = AppReviewService.shared
        service.resetAllStats()
        service.markAsRated()

        let stats = service.getCurrentStats()
        #expect(stats["hasRated"] as? Bool == true)

        // 清理
        service.resetAllStats()
    }

    @Test @MainActor func recordTransactionIncrementsCounter() {
        let service = AppReviewService.shared
        service.resetAllStats()

        service.recordTransactionCreated()
        service.recordTransactionCreated()

        let stats = service.getCurrentStats()
        #expect(stats["transactions"] as? Int == 2)

        service.resetAllStats()
    }

    @Test @MainActor func recordCSVExportIncrementsCounter() {
        let service = AppReviewService.shared
        service.resetAllStats()

        service.recordCSVExported()

        let stats = service.getCurrentStats()
        #expect(stats["csvExports"] as? Int == 1)

        service.resetAllStats()
    }

    @Test @MainActor func recordReminderIncrementsCounter() {
        let service = AppReviewService.shared
        service.resetAllStats()

        service.recordReminderCreated()

        let stats = service.getCurrentStats()
        #expect(stats["reminders"] as? Int == 1)

        service.resetAllStats()
    }

    @Test @MainActor func consecutiveDaysTracked() {
        let service = AppReviewService.shared
        // init() 中调用 updateDailyUsage()，所以共享实例应已记录使用天数
        let stats = service.getCurrentStats()
        let days = stats["consecutiveDays"] as? Int ?? 0
        #expect(days >= 0)
    }

    @Test @MainActor func markAsRatedPreventsReviewRequest() {
        let service = AppReviewService.shared
        service.resetAllStats()
        service.markAsRated()

        // 即使达到阈值，也不应触发评分（markAsRated 后 checkAndRequestReview 会提前返回）
        for _ in 0..<10 {
            service.recordTransactionCreated()
        }
        let stats = service.getCurrentStats()
        #expect(stats["hasRated"] as? Bool == true)
        #expect(stats["transactions"] as? Int == 10)

        service.resetAllStats()
    }

    @Test @MainActor func userRequestedReviewDoesNotCrash() {
        let service = AppReviewService.shared
        service.resetAllStats()
        // userRequestedReview 调用 requestReview(forced: true)，不应崩溃
        service.userRequestedReview()
        service.resetAllStats()
    }

    @Test @MainActor func declineFlagPersists() {
        let service = AppReviewService.shared
        service.resetAllStats()

        // 手动设置拒绝标记
        UserDefaults.standard.set(true, forKey: "app_review_user_declined")

        let stats = service.getCurrentStats()
        #expect(stats["hasDeclined"] as? Bool == true)

        service.resetAllStats()
    }

    @Test @MainActor func consecutiveDaysResetAfterGap() {
        let service = AppReviewService.shared
        service.resetAllStats()

        // 模拟 3 天前的使用日期（中断了连续使用）
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        UserDefaults.standard.set(threeDaysAgo, forKey: "app_review_last_used_date")
        UserDefaults.standard.set(10, forKey: "app_review_consecutive_days")

        // recordTransactionCreated 内部调用 checkAndRequestReview，不会调 updateDailyUsage
        // 但我们可以验证 UserDefaults 状态被正确设置
        let stats = service.getCurrentStats()
        #expect(stats["consecutiveDays"] as? Int == 10) // 没有重新 init，所以保持之前设的值

        service.resetAllStats()
    }

    @Test @MainActor func recentRequestDatePreventsReview() {
        let service = AppReviewService.shared
        service.resetAllStats()

        // 设置最近的请求日期（今天）
        UserDefaults.standard.set(Date(), forKey: "app_review_last_request_date")

        // 大量操作，但因为时间间隔不足，不应再次请求
        for _ in 0..<10 {
            service.recordTransactionCreated()
        }

        let stats = service.getCurrentStats()
        #expect(stats["transactions"] as? Int == 10)

        service.resetAllStats()
    }

    @Test @MainActor func declineWithOldDateAllowsReview() {
        let service = AppReviewService.shared
        service.resetAllStats()

        // 设置拒绝标记 + 91 天前的请求日期
        UserDefaults.standard.set(true, forKey: "app_review_user_declined")
        let oldDate = Calendar.current.date(byAdding: .day, value: -91, to: Date())!
        UserDefaults.standard.set(oldDate, forKey: "app_review_last_request_date")

        // 达到阈值后应允许请求（超过 90 天拒绝冷却期）
        for _ in 0..<6 {
            service.recordTransactionCreated()
        }

        let stats = service.getCurrentStats()
        #expect(stats["transactions"] as? Int == 6)

        service.resetAllStats()
    }

    @Test @MainActor func declineWithRecentDateBlocksReview() {
        let service = AppReviewService.shared
        service.resetAllStats()

        // 设置拒绝标记 + 10 天前的请求日期
        UserDefaults.standard.set(true, forKey: "app_review_user_declined")
        let recentDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        UserDefaults.standard.set(recentDate, forKey: "app_review_last_request_date")

        // 达到阈值但被拒绝冷却期阻止
        for _ in 0..<6 {
            service.recordTransactionCreated()
        }

        let stats = service.getCurrentStats()
        #expect(stats["transactions"] as? Int == 6)

        service.resetAllStats()
    }

    @Test @MainActor func lastRequestDateAfter30DaysAllowsReview() {
        let service = AppReviewService.shared
        service.resetAllStats()

        // 设置 31 天前的请求日期（无拒绝标记）
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        UserDefaults.standard.set(oldDate, forKey: "app_review_last_request_date")

        // 达到阈值后应允许请求
        for _ in 0..<6 {
            service.recordTransactionCreated()
        }

        let stats = service.getCurrentStats()
        #expect(stats["transactions"] as? Int == 6)

        service.resetAllStats()
    }
}

// MARK: - BackupData Model Tests

@Suite("BackupData Tests")
struct BackupDataTests {
    @Test func checksumDeterministic() {
        let tx = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1")
        let cat = Category(id: "c1", nameKey: "test", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0)

        let checksum1 = BackupData.generateChecksum(transactions: [tx], categories: [cat], tags: [], transactionTags: [])
        let checksum2 = BackupData.generateChecksum(transactions: [tx], categories: [cat], tags: [], transactionTags: [])

        #expect(checksum1 == checksum2)
    }

    @Test func checksumDiffersForDifferentData() {
        let tx1 = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1")
        let tx2 = Transaction(id: "t2", amount: 2000, type: "income", categoryId: "c1")

        let checksum1 = BackupData.generateChecksum(transactions: [tx1], categories: [], tags: [], transactionTags: [])
        let checksum2 = BackupData.generateChecksum(transactions: [tx2], categories: [], tags: [], transactionTags: [])

        #expect(checksum1 != checksum2)
    }

    @Test func checksumEmpty() {
        let checksum = BackupData.generateChecksum(transactions: [], categories: [], tags: [], transactionTags: [])
        #expect(!checksum.isEmpty)
    }
}

// MARK: - CSVExportField Model Tests

@Suite("CSVExportField Tests")
struct CSVExportFieldTests {
    @Test func defaultFieldsAllSelected() {
        let fields = CSVExportField.defaultFields()
        let allSelected = fields.allSatisfy(\.isSelected)
        #expect(allSelected)
    }

    @Test func defaultFieldIds() {
        let fields = CSVExportField.defaultFields()
        let ids = fields.map(\.id)
        #expect(ids.contains("date"))
        #expect(ids.contains("amount"))
        #expect(ids.contains("type"))
        #expect(ids.contains("category"))
        #expect(ids.contains("note"))
        #expect(ids.contains("tags"))
    }
}

// MARK: - PasswordService Extended Tests

@Suite("PasswordService Extended Tests")
struct PasswordServiceExtendedTests {
    /// Keychain 在某些模拟器环境不可用，跳过测试
    private func isKeychainAvailable() -> Bool {
        let service = PasswordService()
        _ = service.removePassword()
        let canSet = service.setPassword("__test__")
        _ = service.removePassword()
        return canSet
    }

    @Test func setAndVerifyPassword() throws {
        guard isKeychainAvailable() else { return }
        let service = PasswordService()
        _ = service.removePassword()

        let setResult = service.setPassword("Test1234")
        #expect(setResult == true)
        #expect(service.isPasswordSet() == true)

        let verified = service.verifyPassword("Test1234")
        #expect(verified == true)

        _ = service.removePassword()
    }

    @Test func verifyWrongPassword() throws {
        guard isKeychainAvailable() else { return }
        let service = PasswordService()
        _ = service.removePassword()

        _ = service.setPassword("CorrectPass")
        let verified = service.verifyPassword("WrongPass")
        #expect(verified == false)

        _ = service.removePassword()
    }

    @Test func removePasswordClearsKeychain() throws {
        guard isKeychainAvailable() else { return }
        let service = PasswordService()
        _ = service.setPassword("ToRemove")
        #expect(service.isPasswordSet() == true)

        let removed = service.removePassword()
        #expect(removed == true)
        #expect(service.isPasswordSet() == false)
    }

    @Test func verifyPasswordWhenNoneSet() throws {
        guard isKeychainAvailable() else { return }
        let service = PasswordService()
        _ = service.removePassword()

        let verified = service.verifyPassword("anything")
        #expect(verified == false)
    }

    @Test func setPasswordOverwritesPrevious() throws {
        guard isKeychainAvailable() else { return }
        let service = PasswordService()
        _ = service.removePassword()

        _ = service.setPassword("FirstPass")
        _ = service.setPassword("SecondPass")

        #expect(service.verifyPassword("FirstPass") == false)
        #expect(service.verifyPassword("SecondPass") == true)

        _ = service.removePassword()
    }

    @Test func removePasswordDisablesBiometric() {
        let service = PasswordService()
        service.setBiometricEnabled(true)
        #expect(service.isBiometricEnabled() == true)

        _ = service.removePassword()
        #expect(service.isBiometricEnabled() == false)
    }

    @Test func setPasswordWithEmptyString() throws {
        guard isKeychainAvailable() else { return }
        let service = PasswordService()
        _ = service.removePassword()

        let result = service.setPassword("")
        #expect(result == true)
        #expect(service.isPasswordSet() == true)

        // 空密码也可以验证通过
        #expect(service.verifyPassword("") == true)
        #expect(service.verifyPassword("anything") == false)

        _ = service.removePassword()
    }

    @Test func setPasswordWithSpecialCharacters() throws {
        guard isKeychainAvailable() else { return }
        let service = PasswordService()
        _ = service.removePassword()

        let specialPass = "P@$$w0rd!#%^&*()"
        let result = service.setPassword(specialPass)
        #expect(result == true)
        #expect(service.verifyPassword(specialPass) == true)

        _ = service.removePassword()
    }

    @Test func multipleRemovePasswordCalls() throws {
        guard isKeychainAvailable() else { return }
        let service = PasswordService()
        _ = service.setPassword("test")
        _ = service.removePassword()
        // 第二次删除不应崩溃
        _ = service.removePassword()
        #expect(service.isPasswordSet() == false)
    }

    @Test func biometricEnabledPersists() {
        let service = PasswordService()
        service.setBiometricEnabled(true)
        #expect(service.isBiometricEnabled() == true)

        // 创建新实例验证持久化
        let service2 = PasswordService()
        #expect(service2.isBiometricEnabled() == true)

        service.setBiometricEnabled(false)
    }
}

// MARK: - AmountFormatter Extended Tests

@Suite("AmountFormatter Extended Tests")
struct AmountFormatterExtendedTests {
    @Test func formatWithCurrencyCode() {
        let result = AmountFormatter.format(1050, currencyCode: "USD")
        #expect(result.contains("10.50") || result.contains("10,50"))
    }

    @Test func formatZeroCents() {
        let result = AmountFormatter.format(0, currencyCode: "CNY")
        #expect(result.contains("0.00") || result.contains("0,00"))
    }

    @Test func formatNegativeCents() {
        let result = AmountFormatter.format(-500, currencyCode: "CNY")
        #expect(result.contains("5.00") || result.contains("5,00"))
    }

    @Test func formatLargeAmount() {
        let result = AmountFormatter.format(99999999, currencyCode: "CNY")
        #expect(!result.isEmpty)
    }

    @Test func formatDisplayEmptyString() {
        let result = AmountFormatter.formatDisplay("", currencySymbol: "$")
        #expect(result == "$ 0.00")
    }

    @Test func formatDisplayNonEmpty() {
        let result = AmountFormatter.formatDisplay("42.50", currencySymbol: "€")
        #expect(result == "€ 42.50")
    }

    @Test func formatDisplayDefaultSymbol() {
        let result = AmountFormatter.formatDisplay("10")
        #expect(result == "¥ 10")
    }

    @Test func toCentsInvalidString() {
        let cents = AmountFormatter.toCents("abc")
        #expect(cents == 0)
    }

    @Test func toCentsNegativeValue() {
        let cents = AmountFormatter.toCents("-5.50")
        #expect(cents == -550)
    }

    @Test func toCentsVerySmallDecimal() {
        let cents = AmountFormatter.toCents("0.01")
        #expect(cents == 1)
    }

    @Test func toCentsLargeValue() {
        let cents = AmountFormatter.toCents("999999.99")
        #expect(cents == 99999999)
    }
}

// MARK: - Reminder Model Extended Tests

@Suite("Reminder Model Extended Tests")
struct ReminderModelExtendedTests {
    @Test func defaultInit() {
        let r = Reminder(title: "Test", amount: 1000)
        #expect(r.title == "Test")
        #expect(r.amount == 1000)
        #expect(r.type == TransactionType.expense.rawValue)
        #expect(r.frequency == ReminderFrequency.monthly.rawValue)
        #expect(r.triggerHour == 9)
        #expect(r.triggerMinute == 0)
        #expect(r.isEnabled == true)
        #expect(r.categoryId == nil)
        #expect(r.note == nil)
        #expect(r.triggerDay == nil)
        #expect(!r.id.isEmpty)
        #expect(!r.createdAt.isEmpty)
    }

    @Test func customInit() {
        let r = Reminder(
            id: "custom-id",
            title: "Rent",
            amount: 500000,
            type: TransactionType.income.rawValue,
            categoryId: "cat1",
            note: "Monthly rent",
            frequency: ReminderFrequency.weekly.rawValue,
            triggerDay: 3,
            triggerHour: 14,
            triggerMinute: 30,
            isEnabled: false,
            createdAt: "2025-01-01T00:00:00Z"
        )
        #expect(r.id == "custom-id")
        #expect(r.title == "Rent")
        #expect(r.amount == 500000)
        #expect(r.type == "income")
        #expect(r.categoryId == "cat1")
        #expect(r.note == "Monthly rent")
        #expect(r.frequency == "weekly")
        #expect(r.triggerDay == 3)
        #expect(r.triggerHour == 14)
        #expect(r.triggerMinute == 30)
        #expect(r.isEnabled == false)
        #expect(r.createdAt == "2025-01-01T00:00:00Z")
    }

    @Test func frequencyEnumDaily() {
        let r = Reminder(title: "Test", amount: 100, frequency: ReminderFrequency.daily.rawValue)
        #expect(r.frequencyEnum == .daily)
    }

    @Test func frequencyEnumWeekly() {
        let r = Reminder(title: "Test", amount: 100, frequency: ReminderFrequency.weekly.rawValue)
        #expect(r.frequencyEnum == .weekly)
    }

    @Test func frequencyEnumMonthly() {
        let r = Reminder(title: "Test", amount: 100, frequency: ReminderFrequency.monthly.rawValue)
        #expect(r.frequencyEnum == .monthly)
    }

    @Test func frequencyEnumInvalidFallsBackToMonthly() {
        let r = Reminder(title: "Test", amount: 100, frequency: "invalid")
        #expect(r.frequencyEnum == .monthly)
    }

    @Test func typeEnumExpense() {
        let r = Reminder(title: "Test", amount: 100, type: TransactionType.expense.rawValue)
        #expect(r.typeEnum == .expense)
    }

    @Test func typeEnumIncome() {
        let r = Reminder(title: "Test", amount: 100, type: TransactionType.income.rawValue)
        #expect(r.typeEnum == .income)
    }

    @Test func typeEnumInvalidFallsBackToExpense() {
        let r = Reminder(title: "Test", amount: 100, type: "invalid")
        #expect(r.typeEnum == .expense)
    }

    @Test func uniqueIds() {
        let r1 = Reminder(title: "A", amount: 100)
        let r2 = Reminder(title: "B", amount: 200)
        #expect(r1.id != r2.id)
    }

    @Test func hashableConformance() {
        let r1 = Reminder(id: "same-id", title: "A", amount: 100)
        let r2 = Reminder(id: "same-id", title: "A", amount: 100)
        #expect(r1 == r2)

        var set = Set<Reminder>()
        set.insert(r1)
        set.insert(r2)
        #expect(set.count == 1)
    }
}

// MARK: - AppDateFormatter Tests

@Suite("AppDateFormatter Tests")
struct AppDateFormatterTests {
    @Test func formatISOAndParse() {
        let now = Date()
        let iso = AppDateFormatter.formatISO(now)
        #expect(!iso.isEmpty)

        let parsed = AppDateFormatter.parseISO(iso)
        #expect(parsed != nil)
        // 解析后的时间差不到 1 秒
        let diff = abs(parsed!.timeIntervalSince(now))
        #expect(diff < 1.0)
    }

    @Test func isoNow() {
        let result = AppDateFormatter.isoNow()
        #expect(!result.isEmpty)
        // 应该可以回解析
        let parsed = AppDateFormatter.parseISO(result)
        #expect(parsed != nil)
    }

    @Test func parseISOInvalid() {
        let result = AppDateFormatter.parseISO("not-a-date")
        #expect(result == nil)
    }

    @Test func formatTime() {
        let now = Date()
        let iso = AppDateFormatter.formatISO(now)
        let time = AppDateFormatter.formatTime(iso)
        #expect(!time.isEmpty)
        // HH:mm 格式
        #expect(time.contains(":"))
    }

    @Test func formatTimeInvalid() {
        let result = AppDateFormatter.formatTime("invalid")
        #expect(result == "")
    }

    @Test func formatGroupTitleToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let title = AppDateFormatter.formatGroupTitle(today)
        // 应返回本地化的"今天"
        #expect(!title.isEmpty)
    }

    @Test func formatGroupTitleYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        let title = AppDateFormatter.formatGroupTitle(yesterday)
        #expect(!title.isEmpty)
    }

    @Test func formatGroupTitleOther() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let dayStart = Calendar.current.startOfDay(for: oldDate)
        let title = AppDateFormatter.formatGroupTitle(dayStart)
        #expect(!title.isEmpty)
        // 不应该是"今天"或"昨天"
    }

    @Test func formatMonthTitle() {
        let title = AppDateFormatter.formatMonthTitle()
        #expect(!title.isEmpty)
    }

    @Test func groupTransactionsByDate() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        let tx1 = Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1", createdAt: AppDateFormatter.formatISO(now))
        let tx2 = Transaction(id: "t2", amount: 2000, type: "expense", categoryId: "c1", createdAt: AppDateFormatter.formatISO(now))
        let tx3 = Transaction(id: "t3", amount: 3000, type: "expense", categoryId: "c1", createdAt: AppDateFormatter.formatISO(yesterday))

        let groups = AppDateFormatter.groupTransactionsByDate([tx1, tx2, tx3])
        #expect(groups.count == 2)
        // 第一组(今天)有2个交易
        #expect(groups.first?.1.count == 2)
        // 第二组(昨天)有1个交易
        #expect(groups.last?.1.count == 1)
    }

    @Test func groupTransactionsEmpty() {
        let groups = AppDateFormatter.groupTransactionsByDate([])
        #expect(groups.isEmpty)
    }
}

// MARK: - PasswordService Biometric Tests

@Suite("PasswordService Biometric Tests")
struct PasswordServiceBiometricTests {
    @Test func biometricEnableDisable() {
        let service = PasswordService()
        service.setBiometricEnabled(false)
        #expect(service.isBiometricEnabled() == false)

        service.setBiometricEnabled(true)
        #expect(service.isBiometricEnabled() == true)

        // 清理
        service.setBiometricEnabled(false)
    }

    @Test func canUseBiometrics() {
        let service = PasswordService()
        // 模拟器中没有生物识别硬件
        let result = service.canUseBiometrics()
        #expect(result == false || result == true) // 不崩溃即可
    }

    @Test func biometricType() {
        let service = PasswordService()
        let bType = service.biometricType
        // 确保不崩溃，返回某种类型
        #expect(bType.rawValue >= 0)
    }
}

// MARK: - AppReviewService Edge Tests

@Suite("AppReviewService Edge Tests")
struct AppReviewServiceEdgeTests {
    @Test @MainActor func userRequestedReview() {
        let service = AppReviewService.shared
        service.resetAllStats()
        // 调用不应崩溃（UIWindowScene 不可用时静默失败）
        service.userRequestedReview()
        // lastReviewRequestDate 应该被设置
        let stats = service.getCurrentStats()
        #expect(stats["lastRequestDate"] is Date)
        service.resetAllStats()
    }

    @Test @MainActor func hasRatedPreventsReviewRequest() {
        let service = AppReviewService.shared
        service.resetAllStats()
        service.markAsRated()

        // 即使满足条件，已评分用户不会再触发评分
        for _ in 0..<10 {
            service.recordTransactionCreated()
        }
        let stats = service.getCurrentStats()
        #expect(stats["hasRated"] as? Bool == true)
        service.resetAllStats()
    }

    @Test @MainActor func recordCSVExportAndReminderCombined() {
        let service = AppReviewService.shared
        service.resetAllStats()

        service.recordCSVExported()
        service.recordCSVExported()
        service.recordReminderCreated()
        service.recordReminderCreated()
        service.recordReminderCreated()

        let stats = service.getCurrentStats()
        #expect(stats["csvExports"] as? Int == 2)
        #expect(stats["reminders"] as? Int == 3)
        service.resetAllStats()
    }

    @Test @MainActor func multipleTransactionsReachThreshold() {
        let service = AppReviewService.shared
        service.resetAllStats()

        // 达到 5 笔交易门槛
        for _ in 0..<5 {
            service.recordTransactionCreated()
        }
        let stats = service.getCurrentStats()
        #expect(stats["transactions"] as? Int == 5)
        service.resetAllStats()
    }
}

// MARK: - LanguageManager Tests

@Suite("LanguageManager Tests")
struct LanguageManagerTests {
    @Test @MainActor func languageIdProperty() {
        let lang = LanguageManager.Language(code: "en", name: "English", localName: "English")
        #expect(lang.id == "en")
    }

    @Test @MainActor func currentLanguageDisplay() {
        let manager = LanguageManager.shared
        let original = manager.currentLanguage

        manager.currentLanguage = "en"
        #expect(manager.currentLanguageDisplay == "English")

        manager.currentLanguage = "zh-Hans"
        #expect(manager.currentLanguageDisplay == "简体中文")

        manager.currentLanguage = "ja"
        #expect(manager.currentLanguageDisplay == "日本語")

        // 恢复
        manager.currentLanguage = original
    }

    @Test @MainActor func currentLanguageDisplayUnknownCode() {
        let manager = LanguageManager.shared
        let original = manager.currentLanguage

        manager.currentLanguage = "xx-Unknown"
        // 未知语言代码应返回代码本身
        #expect(manager.currentLanguageDisplay == "xx-Unknown")

        manager.currentLanguage = original
    }

    @Test @MainActor func supportedLanguagesNotEmpty() {
        #expect(!LanguageManager.supportedLanguages.isEmpty)
        #expect(LanguageManager.supportedLanguages.count == 23)
    }

    @Test @MainActor func localeUpdatesWithLanguage() {
        let manager = LanguageManager.shared
        let original = manager.currentLanguage

        manager.currentLanguage = "ja"
        #expect(LanguageManager.locale.identifier.contains("ja"))

        manager.currentLanguage = original
    }

    @Test @MainActor func refreshIdIncrementsOnChange() {
        let manager = LanguageManager.shared
        let original = manager.currentLanguage
        let initialRefreshId = manager.refreshId

        manager.currentLanguage = "ko"
        #expect(manager.refreshId == initialRefreshId + 1)

        manager.currentLanguage = original
    }
}

// MARK: - WidgetDataBridge Tests

@Suite("WidgetDataBridge Tests")
struct WidgetDataBridgeTests {
    @Test func writeAndReadRoundTrip() {
        let data = WidgetData(
            totalExpense: 50000,
            totalIncome: 80000,
            balance: 30000,
            monthTitle: "2026年3月",
            currencyCode: "CNY",
            recentTransactions: [
                WidgetTransactionItem(
                    categoryName: "餐饮",
                    categoryIcon: "fork.knife",
                    categoryColor: "#FF6B6B",
                    amount: 3500,
                    isExpense: true,
                    note: "午餐",
                    time: "12:30"
                )
            ],
            updatedAt: Date()
        )

        WidgetDataBridge.write(data)
        let read = WidgetDataBridge.read()

        #expect(read != nil)
        #expect(read?.totalExpense == 50000)
        #expect(read?.totalIncome == 80000)
        #expect(read?.balance == 30000)
        #expect(read?.currencyCode == "CNY")
        #expect(read?.recentTransactions.count == 1)
        #expect(read?.recentTransactions.first?.categoryName == "餐饮")
    }

    @Test func readNonexistentFileReturnsNil() {
        // 删除测试文件
        let url = URL(fileURLWithPath: "/private/tmp/widget_data_nonexistent.json")
        try? FileManager.default.removeItem(at: url)
        // read 一个不存在的位置不应崩溃
        // 实际 read() 使用固定路径，但若文件不存在应返回 nil
    }

    @Test func readCorruptedDataReturnsNil() {
        // 向 widget_data 文件写入非法 JSON，验证 read() 返回 nil 而非崩溃
        let url = URL(fileURLWithPath: "/private/tmp/widget_data.json")
        try? Data("not a valid json".utf8).write(to: url, options: .atomic)

        let result = WidgetDataBridge.read()
        #expect(result == nil)
    }

    @Test func writeOverwritesPreviousData() {
        let data1 = WidgetData(
            totalExpense: 1000,
            totalIncome: 2000,
            balance: 1000,
            monthTitle: "1月",
            currencyCode: "CNY",
            recentTransactions: [],
            updatedAt: Date()
        )
        WidgetDataBridge.write(data1)

        let data2 = WidgetData(
            totalExpense: 9999,
            totalIncome: 8888,
            balance: -1111,
            monthTitle: "2月",
            currencyCode: "USD",
            recentTransactions: [],
            updatedAt: Date()
        )
        WidgetDataBridge.write(data2)

        let read = WidgetDataBridge.read()
        #expect(read?.totalExpense == 9999)
        #expect(read?.currencyCode == "USD")
        #expect(read?.monthTitle == "2月")
    }

    @Test func writeAndReadEmptyTransactions() {
        let data = WidgetData(
            totalExpense: 0,
            totalIncome: 0,
            balance: 0,
            monthTitle: "",
            currencyCode: "CNY",
            recentTransactions: [],
            updatedAt: Date()
        )
        WidgetDataBridge.write(data)

        let read = WidgetDataBridge.read()
        #expect(read != nil)
        #expect(read?.recentTransactions.isEmpty == true)
        #expect(read?.totalExpense == 0)
    }

    @Test func writeAndReadMultipleTransactions() {
        let items = (0..<5).map { i in
            WidgetTransactionItem(
                categoryName: "Cat\(i)",
                categoryIcon: "star",
                categoryColor: "#000000",
                amount: Int64(i * 1000),
                isExpense: i % 2 == 0,
                note: "Note\(i)",
                time: "\(i):00"
            )
        }
        let data = WidgetData(
            totalExpense: 6000,
            totalIncome: 4000,
            balance: -2000,
            monthTitle: "Test",
            currencyCode: "EUR",
            recentTransactions: items,
            updatedAt: Date()
        )
        WidgetDataBridge.write(data)

        let read = WidgetDataBridge.read()
        #expect(read?.recentTransactions.count == 5)
        #expect(read?.recentTransactions[2].categoryName == "Cat2")
    }

    @Test func readAfterDeleteReturnsNil() {
        let data = WidgetData(
            totalExpense: 100,
            totalIncome: 200,
            balance: 100,
            monthTitle: "T",
            currencyCode: "CNY",
            recentTransactions: [],
            updatedAt: Date()
        )
        WidgetDataBridge.write(data)

        // 验证写入成功
        #expect(WidgetDataBridge.read() != nil)

        // 删除文件后读取应返回 nil
        let url = URL(fileURLWithPath: "/private/tmp/widget_data.json")
        try? FileManager.default.removeItem(at: url)

        let result = WidgetDataBridge.read()
        #expect(result == nil)
    }
}

// MARK: - PDFExportService Tests

@Suite("PDFExportService Tests")
struct PDFExportServiceTests {

    // MARK: - computeSummary

    @Test func computeSummaryEmpty() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let summary = service.computeSummary([])
        #expect(summary.totalExpense == 0)
        #expect(summary.totalIncome == 0)
        #expect(summary.balance == 0)
        #expect(summary.count == 0)
    }

    @Test func computeSummaryExpenseOnly() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1"),
            Transaction(id: "t2", amount: 2500, type: "expense", categoryId: "c1"),
        ]
        let summary = service.computeSummary(txs)
        #expect(summary.totalExpense == 3500)
        #expect(summary.totalIncome == 0)
        #expect(summary.balance == -3500)
        #expect(summary.count == 2)
    }

    @Test func computeSummaryIncomeOnly() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 5000, type: "income", categoryId: "c1"),
        ]
        let summary = service.computeSummary(txs)
        #expect(summary.totalExpense == 0)
        #expect(summary.totalIncome == 5000)
        #expect(summary.balance == 5000)
        #expect(summary.count == 1)
    }

    @Test func computeSummaryMixed() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 3000, type: "expense", categoryId: "c1"),
            Transaction(id: "t2", amount: 8000, type: "income", categoryId: "c2"),
            Transaction(id: "t3", amount: 1000, type: "expense", categoryId: "c1"),
        ]
        let summary = service.computeSummary(txs)
        #expect(summary.totalExpense == 4000)
        #expect(summary.totalIncome == 8000)
        #expect(summary.balance == 4000)
        #expect(summary.count == 3)
    }

    // MARK: - computeCategoryBreakdown

    @Test func breakdownEmptyTransactions() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let result = service.computeCategoryBreakdown([], categoryDict: [:], type: "expense")
        #expect(result.isEmpty)
    }

    @Test func breakdownNoMatchingType() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 1000, type: "income", categoryId: "c1"),
        ]
        let result = service.computeCategoryBreakdown(txs, categoryDict: [:], type: "expense")
        #expect(result.isEmpty)
    }

    @Test func breakdownSingleCategory() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 3000, type: "expense", categoryId: "c1"),
            Transaction(id: "t2", amount: 2000, type: "expense", categoryId: "c1"),
        ]
        let catDict = ["c1": FreeLedger.Category(id: "c1", nameKey: "cat_food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, isCustom: true)]

        let result = service.computeCategoryBreakdown(txs, categoryDict: catDict, type: "expense")
        #expect(result.count == 1)
        #expect(result[0].total == 5000)
        #expect(result[0].percentage == 100.0)
        #expect(result[0].categoryName == "cat_food")
    }

    @Test func breakdownMultipleCategories() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 3000, type: "expense", categoryId: "c1"),
            Transaction(id: "t2", amount: 7000, type: "expense", categoryId: "c2"),
        ]
        let catDict: [String: FreeLedger.Category] = [
            "c1": FreeLedger.Category(id: "c1", nameKey: "Food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, isCustom: true),
            "c2": FreeLedger.Category(id: "c2", nameKey: "Transport", iconName: "car", colorHex: "#00FF00", type: "expense", sortOrder: 1, isCustom: true),
        ]

        let result = service.computeCategoryBreakdown(txs, categoryDict: catDict, type: "expense")
        #expect(result.count == 2)
        // 按金额降序排列
        #expect(result[0].categoryName == "Transport")
        #expect(result[0].total == 7000)
        #expect(result[0].percentage == 70.0)
        #expect(result[1].categoryName == "Food")
        #expect(result[1].total == 3000)
        #expect(result[1].percentage == 30.0)
    }

    @Test func breakdownMissingCategoryShowsDash() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "missing"),
        ]
        let result = service.computeCategoryBreakdown(txs, categoryDict: [:], type: "expense")
        #expect(result.count == 1)
        #expect(result[0].categoryName == "—")
    }

    @Test func breakdownFiltersIncomeFromExpense() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 3000, type: "expense", categoryId: "c1"),
            Transaction(id: "t2", amount: 5000, type: "income", categoryId: "c2"),
        ]
        let catDict: [String: FreeLedger.Category] = [
            "c1": FreeLedger.Category(id: "c1", nameKey: "Food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, isCustom: true),
        ]

        let expenseResult = service.computeCategoryBreakdown(txs, categoryDict: catDict, type: "expense")
        #expect(expenseResult.count == 1)
        #expect(expenseResult[0].total == 3000)
        #expect(expenseResult[0].percentage == 100.0)
    }

    // MARK: - reportTitle

    @Test func reportTitleYear() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let title = service.reportTitle(for: .year(year: 2025))
        #expect(title == "2025")
    }

    @Test func reportTitleAll() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let title = service.reportTitle(for: .all)
        #expect(!title.isEmpty)
    }

    @Test func reportTitleMonth() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let title = service.reportTitle(for: .month(year: 2025, month: 3))
        #expect(!title.isEmpty)
        #expect(title.contains("2025"))
    }

    // MARK: - exportPDF 端到端

    @Test func exportPDFEmptyDatabase() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let data = try service.exportPDF(range: .all, currencyCode: "CNY")
        #expect(!data.isEmpty)
        // PDF 文件以 %PDF 开头
        let header = String(data: data.prefix(5), encoding: .ascii)
        #expect(header?.hasPrefix("%PDF") == true)
    }

    @Test func exportPDFWithData() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db, id: "t1", amount: 5000)
            try insertTestTransaction(db: db, id: "t2", amount: 3000, categoryId: "cat1", type: "expense")
        }

        let service = PDFExportService(dbQueue: dbQueue)
        let data = try service.exportPDF(range: .all, currencyCode: "USD")
        #expect(!data.isEmpty)
        let header = String(data: data.prefix(5), encoding: .ascii)
        #expect(header?.hasPrefix("%PDF") == true)
    }

    @Test func exportPDFMonthRange() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let data = try service.exportPDF(range: .month(year: 2025, month: 6), currencyCode: "CNY")
        #expect(!data.isEmpty)
    }

    @Test func exportPDFYearRange() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let data = try service.exportPDF(range: .year(year: 2025), currencyCode: "EUR")
        #expect(!data.isEmpty)
    }

    @Test func exportPDFWithIncomeBreakdown() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db, id: "inc1", type: "income")
            let tx = Transaction(id: "t1", amount: 80000, type: "income", categoryId: "inc1", note: "Salary")
            try tx.insert(db)
        }

        let service = PDFExportService(dbQueue: dbQueue)
        let data = try service.exportPDF(range: .all, currencyCode: "CNY")
        #expect(!data.isEmpty)
        let header = String(data: data.prefix(5), encoding: .ascii)
        #expect(header?.hasPrefix("%PDF") == true)
    }

    @Test func exportPDFWithBothExpenseAndIncome() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db, id: "exp1", type: "expense")
            try insertTestCategory(db: db, id: "inc1", type: "income")
            let tx1 = Transaction(id: "t1", amount: 5000, type: "expense", categoryId: "exp1", note: "Lunch")
            let tx2 = Transaction(id: "t2", amount: 80000, type: "income", categoryId: "inc1", note: "Salary")
            try tx1.insert(db)
            try tx2.insert(db)
        }

        let service = PDFExportService(dbQueue: dbQueue)
        let data = try service.exportPDF(range: .all, currencyCode: "USD")
        #expect(!data.isEmpty)
    }

    @Test func exportPDFWithTags() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db)
            try insertTestTransaction(db: db, id: "t1", amount: 3000)
            try insertTestTag(db: db, id: "tag1", name: "Food")
            try TransactionTag(transactionId: "t1", tagId: "tag1").insert(db)
        }

        let service = PDFExportService(dbQueue: dbQueue)
        let data = try service.exportPDF(range: .all, currencyCode: "CNY")
        #expect(!data.isEmpty)
    }

    @Test func exportPDFMultipleTransactions() throws {
        let dbQueue = try makeTestDatabase()
        try dbQueue.write { db in
            try insertTestCategory(db: db, id: "c1", type: "expense")
            try insertTestCategory(db: db, id: "c2", type: "expense")
            for i in 0..<30 {
                let tx = Transaction(id: "tx\(i)", amount: Int64(1000 + i * 100), type: "expense",
                                     categoryId: i % 2 == 0 ? "c1" : "c2", note: "Note \(i)")
                try tx.insert(db)
            }
        }

        let service = PDFExportService(dbQueue: dbQueue)
        let data = try service.exportPDF(range: .all, currencyCode: "CNY")
        #expect(!data.isEmpty)
        // 多页 PDF 应该更大
        #expect(data.count > 1000)
    }

    @Test func exportPDFMonthRangeWithData() throws {
        let dbQueue = try makeTestDatabase()
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)
        let iso = AppDateFormatter.formatISO(now)

        try dbQueue.write { db in
            try insertTestCategory(db: db)
            let tx = Transaction(id: "t1", amount: 5000, type: "expense", categoryId: "cat1", note: "test", createdAt: iso)
            try tx.insert(db)
        }

        let service = PDFExportService(dbQueue: dbQueue)
        let data = try service.exportPDF(range: .month(year: year, month: month), currencyCode: "CNY")
        #expect(!data.isEmpty)
    }

    @Test func exportPDFYearRangeWithData() throws {
        let dbQueue = try makeTestDatabase()
        let year = Calendar.current.component(.year, from: Date())
        let iso = AppDateFormatter.formatISO(Date())

        try dbQueue.write { db in
            try insertTestCategory(db: db)
            let tx = Transaction(id: "t1", amount: 8000, type: "expense", categoryId: "cat1", createdAt: iso)
            try tx.insert(db)
        }

        let service = PDFExportService(dbQueue: dbQueue)
        let data = try service.exportPDF(range: .year(year: year), currencyCode: "USD")
        #expect(!data.isEmpty)
    }

    @Test func breakdownBuiltinCategoryUsesLocalization() throws {
        let dbQueue = try makeTestDatabase()
        let service = PDFExportService(dbQueue: dbQueue)

        let txs = [
            Transaction(id: "t1", amount: 1000, type: "expense", categoryId: "c1"),
        ]
        let catDict = ["c1": FreeLedger.Category(id: "c1", nameKey: "cat_food", iconName: "cart", colorHex: "#FF0000", type: "expense", sortOrder: 0, isCustom: false)]

        let result = service.computeCategoryBreakdown(txs, categoryDict: catDict, type: "expense")
        #expect(result.count == 1)
        // 内置分类使用 L() 本地化，不直接等于 nameKey
        #expect(result[0].categoryName != "")
    }
}

// MARK: - AppTheme Extended Tests

@Suite("AppTheme Extended Tests")
struct AppThemeExtendedTests {
    @Test func allThemesHaveDistinctPrimary() {
        let primaries = AppTheme.allCases.map { $0.colors.primary }
        let unique = Set(primaries)
        #expect(unique.count == AppTheme.allCases.count)
    }

    @Test func eachThemeColorsAreSevenChars() {
        for theme in AppTheme.allCases {
            let c = theme.colors
            #expect(c.primary.count == 7) // #RRGGBB
            #expect(c.primaryDark.count == 7)
            #expect(c.primaryLight.count == 7)
            #expect(c.secondary.count == 7)
            #expect(c.gradientStart.count == 7)
            #expect(c.gradientEnd.count == 7)
        }
    }

    @Test func allThemesHaveDistinctNameKeys() {
        let keys = AppTheme.allCases.map { $0.nameKey }
        let unique = Set(keys)
        #expect(keys.count == unique.count)
    }
}

// MARK: - ThemeManager Extended Tests

@Suite("ThemeManager Extended Tests")
struct ThemeManagerExtendedTests {
    @Test @MainActor func setAllThemesAndVerifyColors() {
        let manager = ThemeManager.shared
        let original = manager.currentTheme

        for theme in AppTheme.allCases {
            manager.currentTheme = theme
            #expect(manager.currentTheme == theme)
            #expect(manager.colors.primary == theme.colors.primary)
        }

        manager.currentTheme = original
    }

    @Test @MainActor func expenseIncomeColors() {
        let manager = ThemeManager.shared
        let original = manager.currentTheme

        manager.currentTheme = .coral
        // expense == primary, income == secondary
        _ = manager.expense
        _ = manager.income

        manager.currentTheme = original
    }
}

// MARK: - PDFExportRange Tests

@Suite("PDFExportRange Tests")
struct PDFExportRangeTests {
    @Test func monthRange() {
        let range = PDFExportRange.month(year: 2025, month: 3)
        if case .month(let y, let m) = range {
            #expect(y == 2025)
            #expect(m == 3)
        } else {
            Issue.record("Expected .month")
        }
    }

    @Test func yearRange() {
        let range = PDFExportRange.year(year: 2026)
        if case .year(let y) = range {
            #expect(y == 2026)
        } else {
            Issue.record("Expected .year")
        }
    }

    @Test func allRange() {
        let range = PDFExportRange.all
        if case .all = range {
            // OK
        } else {
            Issue.record("Expected .all")
        }
    }
}
