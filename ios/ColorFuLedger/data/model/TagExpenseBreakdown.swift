import Foundation

struct TagExpenseBreakdown: Identifiable {
    let id: String
    let tagName: String
    let colorHex: String
    let total: Int64

    init(tagId: String, tagName: String, colorHex: String, total: Int64) {
        self.id = tagId
        self.tagName = tagName
        self.colorHex = colorHex
        self.total = total
    }
}
