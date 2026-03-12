import Foundation
import GRDB

struct Budget: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var amount: Int64
    var categoryId: String?
    var createdAt: String
    var updatedAt: String

    static let databaseTableName = "budgets"

    enum Columns: String, ColumnExpression {
        case id, amount
        case categoryId = "category_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum CodingKeys: String, CodingKey {
        case id, amount
        case categoryId = "category_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// categoryId == nil 表示总预算，否则为分类预算
    var isOverall: Bool { categoryId == nil }

    init(id: String = UUID().uuidString,
         amount: Int64,
         categoryId: String? = nil,
         createdAt: String? = nil,
         updatedAt: String? = nil) {
        self.id = id
        self.amount = amount
        self.categoryId = categoryId
        let now = AppDateFormatter.isoNow()
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
    }
}
