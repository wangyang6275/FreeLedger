import Foundation
import GRDB

struct TransactionTag: Codable, FetchableRecord, PersistableRecord {
    var transactionId: String
    var tagId: String

    static let databaseTableName = "transaction_tags"

    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
        case tagId = "tag_id"
    }
}
