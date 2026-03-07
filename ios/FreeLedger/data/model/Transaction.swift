import Foundation
import GRDB

enum TransactionType: String, Codable {
    case expense
    case income
}

struct Transaction: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var amount: Int64
    var type: String
    var categoryId: String
    var note: String?
    var createdAt: String
    var updatedAt: String

    static let databaseTableName = "transactions"

    enum Columns: String, ColumnExpression {
        case id, amount, type
        case categoryId = "category_id"
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum CodingKeys: String, CodingKey {
        case id, amount, type
        case categoryId = "category_id"
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func currentISO() -> String {
        AppDateFormatter.isoNow()
    }

    init(id: String = UUID().uuidString,
         amount: Int64,
         type: String,
         categoryId: String,
         note: String? = nil,
         createdAt: String? = nil,
         updatedAt: String? = nil) {
        self.id = id
        self.amount = amount
        self.type = type
        self.categoryId = categoryId
        self.note = note
        let now = AppDateFormatter.isoNow()
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
    }
}
