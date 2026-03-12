import Foundation
import GRDB

struct Setting: Codable, FetchableRecord, PersistableRecord {
    var key: String
    var value: String

    static let databaseTableName = "settings"

    enum Columns: String, ColumnExpression {
        case key, value
    }
}
