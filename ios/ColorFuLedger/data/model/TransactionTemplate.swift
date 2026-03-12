import Foundation
import GRDB

struct TransactionTemplate: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var title: String
    var amount: Int64
    var type: String
    var categoryId: String
    var note: String?
    var sortOrder: Int
    var createdAt: String

    static let databaseTableName = "transaction_templates"

    enum Columns: String, ColumnExpression {
        case id, title, amount, type
        case categoryId = "category_id"
        case note
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    enum CodingKeys: String, CodingKey {
        case id, title, amount, type
        case categoryId = "category_id"
        case note
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    init(id: String = UUID().uuidString,
         title: String,
         amount: Int64,
         type: String = TransactionType.expense.rawValue,
         categoryId: String,
         note: String? = nil,
         sortOrder: Int = 0,
         createdAt: String? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.categoryId = categoryId
        self.note = note
        self.sortOrder = sortOrder
        self.createdAt = createdAt ?? AppDateFormatter.isoNow()
    }
}
