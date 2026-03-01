import Foundation
import Observation

@Observable
final class RemindersViewModel {
    var reminders: [Reminder] = []
    var categories: [Category] = []
    var errorMessage: String?
    var currencyCode: String = "CNY"

    private let reminderRepository: ReminderRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    var isEmpty: Bool { reminders.isEmpty }

    init(reminderRepository: ReminderRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.reminderRepository = reminderRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
    }

    func loadData() {
        do {
            reminders = try reminderRepository.getAll()
            let expense = try categoryRepository.getExpenseCategories(sortedByUsage: true)
            let income = try categoryRepository.getIncomeCategories(sortedByUsage: true)
            categories = expense + income
            currencyCode = try settingsRepository.getCurrency()
        } catch {
            errorMessage = L("error_load_failed")
        }
    }

    func category(for id: String?) -> Category? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    func createReminder(_ reminder: Reminder) {
        do {
            try reminderRepository.create(reminder)
            NotificationService.scheduleReminder(reminder, currencyCode: currencyCode)
            loadData()

            // 记录提醒创建，触发评分检查
            AppReviewService.shared.recordReminderCreated()
        } catch {
            errorMessage = L("error_save_failed")
        }
    }

    func updateReminder(_ reminder: Reminder) {
        do {
            try reminderRepository.update(reminder)
            NotificationService.scheduleReminder(reminder, currencyCode: currencyCode)
            loadData()
        } catch {
            errorMessage = L("error_save_failed")
        }
    }

    func deleteReminder(id: String) {
        do {
            try reminderRepository.delete(id: id)
            NotificationService.cancelReminder(id: id)
            loadData()
        } catch {
            errorMessage = L("error_save_failed")
        }
    }

    func toggleEnabled(_ reminder: Reminder) {
        var updated = reminder
        updated.isEnabled.toggle()
        updateReminder(updated)
    }
}
