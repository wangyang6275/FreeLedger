import Foundation
import GRDB

struct Category: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Hashable {
    var id: String
    var nameKey: String
    var iconName: String
    var colorHex: String
    var type: String
    var sortOrder: Int
    var usageCount: Int
    var isCustom: Bool
    var isActive: Bool

    static let databaseTableName = "categories"

    enum Columns: String, ColumnExpression {
        case id
        case nameKey = "name_key"
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case type
        case sortOrder = "sort_order"
        case usageCount = "usage_count"
        case isCustom = "is_custom"
        case isActive = "is_active"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case nameKey = "name_key"
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case type
        case sortOrder = "sort_order"
        case usageCount = "usage_count"
        case isCustom = "is_custom"
        case isActive = "is_active"
    }

    init(id: String = UUID().uuidString,
         nameKey: String,
         iconName: String,
         colorHex: String,
         type: String,
         sortOrder: Int,
         usageCount: Int = 0,
         isCustom: Bool = false,
         isActive: Bool = true) {
        self.id = id
        self.nameKey = nameKey
        self.iconName = iconName
        self.colorHex = colorHex
        self.type = type
        self.sortOrder = sortOrder
        self.usageCount = usageCount
        self.isCustom = isCustom
        self.isActive = isActive
    }
}
