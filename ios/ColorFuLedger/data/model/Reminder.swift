import Foundation
import GRDB

enum ReminderFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
}

struct Reminder: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var title: String
    var amount: Int64
    var type: String
    var categoryId: String?
    var note: String?
    var frequency: String
    var triggerDay: Int?
    var triggerHour: Int
    var triggerMinute: Int
    var isEnabled: Bool
    var createdAt: String

    static let databaseTableName = "reminders"

    enum CodingKeys: String, CodingKey {
        case id, title, amount, type, note, frequency
        case categoryId = "category_id"
        case triggerDay = "trigger_day"
        case triggerHour = "trigger_hour"
        case triggerMinute = "trigger_minute"
        case isEnabled = "is_enabled"
        case createdAt = "created_at"
    }

    init(id: String = UUID().uuidString,
         title: String,
         amount: Int64,
         type: String = TransactionType.expense.rawValue,
         categoryId: String? = nil,
         note: String? = nil,
         frequency: String = ReminderFrequency.monthly.rawValue,
         triggerDay: Int? = nil,
         triggerHour: Int = 9,
         triggerMinute: Int = 0,
         isEnabled: Bool = true,
         createdAt: String? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.categoryId = categoryId
        self.note = note
        self.frequency = frequency
        self.triggerDay = triggerDay
        self.triggerHour = triggerHour
        self.triggerMinute = triggerMinute
        self.isEnabled = isEnabled
        self.createdAt = createdAt ?? AppDateFormatter.isoNow()
    }

    var frequencyEnum: ReminderFrequency {
        ReminderFrequency(rawValue: frequency) ?? .monthly
    }

    var typeEnum: TransactionType {
        TransactionType(rawValue: type) ?? .expense
    }
}
