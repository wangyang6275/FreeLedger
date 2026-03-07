import Foundation

enum AchievementCategory: String, Codable, CaseIterable {
    case recording   // 记账相关
    case streak      // 连续记账
    case budget      // 预算相关
    case exploration // 功能探索
}

struct Achievement: Identifiable, Codable {
    let id: String
    let category: AchievementCategory
    let iconName: String
    let titleKey: String
    let descriptionKey: String
    let threshold: Int
    var isUnlocked: Bool = false
    var unlockedAt: Date?

    static let allAchievements: [Achievement] = [
        // Recording milestones
        Achievement(id: "first_record", category: .recording, iconName: "pencil.circle.fill", titleKey: "achievement_first_record", descriptionKey: "achievement_first_record_desc", threshold: 1),
        Achievement(id: "records_10", category: .recording, iconName: "flame.fill", titleKey: "achievement_records_10", descriptionKey: "achievement_records_10_desc", threshold: 10),
        Achievement(id: "records_50", category: .recording, iconName: "star.fill", titleKey: "achievement_records_50", descriptionKey: "achievement_records_50_desc", threshold: 50),
        Achievement(id: "records_100", category: .recording, iconName: "trophy.fill", titleKey: "achievement_records_100", descriptionKey: "achievement_records_100_desc", threshold: 100),
        Achievement(id: "records_500", category: .recording, iconName: "crown.fill", titleKey: "achievement_records_500", descriptionKey: "achievement_records_500_desc", threshold: 500),
        Achievement(id: "records_1000", category: .recording, iconName: "medal.fill", titleKey: "achievement_records_1000", descriptionKey: "achievement_records_1000_desc", threshold: 1000),

        // Streak milestones
        Achievement(id: "streak_3", category: .streak, iconName: "bolt.fill", titleKey: "achievement_streak_3", descriptionKey: "achievement_streak_3_desc", threshold: 3),
        Achievement(id: "streak_7", category: .streak, iconName: "bolt.circle.fill", titleKey: "achievement_streak_7", descriptionKey: "achievement_streak_7_desc", threshold: 7),
        Achievement(id: "streak_30", category: .streak, iconName: "bolt.shield.fill", titleKey: "achievement_streak_30", descriptionKey: "achievement_streak_30_desc", threshold: 30),
        Achievement(id: "streak_100", category: .streak, iconName: "bolt.star.fill", titleKey: "achievement_streak_100", descriptionKey: "achievement_streak_100_desc", threshold: 100),
        Achievement(id: "streak_365", category: .streak, iconName: "sparkles", titleKey: "achievement_streak_365", descriptionKey: "achievement_streak_365_desc", threshold: 365),

        // Budget milestones
        Achievement(id: "budget_set", category: .budget, iconName: "target", titleKey: "achievement_budget_set", descriptionKey: "achievement_budget_set_desc", threshold: 1),
        Achievement(id: "budget_under_3", category: .budget, iconName: "hand.thumbsup.fill", titleKey: "achievement_budget_under_3", descriptionKey: "achievement_budget_under_3_desc", threshold: 3),

        // Exploration milestones
        Achievement(id: "first_tag", category: .exploration, iconName: "tag.fill", titleKey: "achievement_first_tag", descriptionKey: "achievement_first_tag_desc", threshold: 1),
        Achievement(id: "first_export", category: .exploration, iconName: "square.and.arrow.up.fill", titleKey: "achievement_first_export", descriptionKey: "achievement_first_export_desc", threshold: 1),
        Achievement(id: "first_template", category: .exploration, iconName: "doc.on.doc.fill", titleKey: "achievement_first_template", descriptionKey: "achievement_first_template_desc", threshold: 1),
    ]
}
