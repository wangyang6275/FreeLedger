import Foundation

/// 统一依赖容器，集中管理所有 DAO / Repository / Service 的创建
final class DependencyContainer {
    let db = AppDatabase.shared

    // MARK: - DAOs
    let categoryDAO: CategoryDAO
    let transactionDAO: TransactionDAO
    let settingsDAO: SettingsDAO
    let tagDAO: TagDAO
    let reminderDAO: ReminderDAO
    let budgetDAO: BudgetDAO
    let templateDAO: TransactionTemplateDAO

    // MARK: - Repositories
    let transactionRepository: TransactionRepository
    let categoryRepository: CategoryRepository
    let settingsRepository: SettingsRepository
    let tagRepository: TagRepository
    let reminderRepository: ReminderRepository
    let budgetRepository: BudgetRepository
    let templateRepository: TransactionTemplateRepository

    // MARK: - Services
    let backupService: BackupService
    let backupReminderService: BackupReminderService
    let csvExportService: CSVExportService
    let passwordService: PasswordService
    let achievementService: AchievementService

    init() {
        let dbQueue = db.dbQueue

        // DAOs
        categoryDAO = CategoryDAO(dbQueue: dbQueue)
        transactionDAO = TransactionDAO(dbQueue: dbQueue)
        settingsDAO = SettingsDAO(dbQueue: dbQueue)
        tagDAO = TagDAO(dbQueue: dbQueue)
        reminderDAO = ReminderDAO(dbQueue: dbQueue)
        budgetDAO = BudgetDAO(dbQueue: dbQueue)
        templateDAO = TransactionTemplateDAO(dbQueue: dbQueue)

        // Repositories
        transactionRepository = TransactionRepository(
            dbQueue: dbQueue,
            transactionDAO: transactionDAO,
            categoryDAO: categoryDAO,
            tagDAO: tagDAO
        )
        categoryRepository = CategoryRepository(dao: categoryDAO)
        settingsRepository = SettingsRepository(dao: settingsDAO)
        tagRepository = TagRepository(dao: tagDAO)
        reminderRepository = ReminderRepository(dao: reminderDAO)
        budgetRepository = BudgetRepository(dao: budgetDAO)
        templateRepository = TransactionTemplateRepository(dao: templateDAO)

        // Services
        backupService = BackupService(dbQueue: dbQueue)
        backupReminderService = BackupReminderService(dbQueue: dbQueue, settingsDAO: settingsDAO)
        csvExportService = CSVExportService(dbQueue: dbQueue)
        passwordService = PasswordService()
        achievementService = AchievementService(dbQueue: dbQueue)
    }
}
