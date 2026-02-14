import Foundation

struct CategoryBreakdown: Identifiable {
    let id: String
    let categoryId: String
    let categoryName: String
    let iconName: String
    let colorHex: String
    let total: Int64
    let percentage: Double

    init(categoryId: String, categoryName: String, iconName: String, colorHex: String, total: Int64, percentage: Double) {
        self.id = categoryId
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.iconName = iconName
        self.colorHex = colorHex
        self.total = total
        self.percentage = percentage
    }
}
