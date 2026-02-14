import Foundation
import GRDB

struct Tag: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var name: String
    var colorHex: String
    var createdAt: String

    static let databaseTableName = "tags"

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case colorHex = "color_hex"
        case createdAt = "created_at"
    }

    init(id: String = UUID().uuidString, name: String, colorHex: String, createdAt: String? = nil) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt ?? ISO8601DateFormatter().string(from: Date())
    }
}
