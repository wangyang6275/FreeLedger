import Foundation
import GRDB

final class AchievementService {
    private let dbQueue: DatabaseQueue
    private let storageKey = "unlocked_achievements"

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    // MARK: - Public

    func getAchievements() -> [Achievement] {
        let unlocked = loadUnlockedSet()
        return Achievement.allAchievements.map { a in
            var achievement = a
            if let date = unlocked[a.id] {
                achievement.isUnlocked = true
                achievement.unlockedAt = date
            }
            return achievement
        }
    }

    func evaluateAll() -> [Achievement] {
        var unlocked = loadUnlockedSet()
        var newlyUnlocked: [Achievement] = []

        let totalCount = (try? getTotalTransactionCount()) ?? 0
        let streak = (try? getCurrentStreak()) ?? 0
        let budgetCount = (try? getBudgetCount()) ?? 0
        let budgetUnderCount = (try? getMonthsUnderBudget()) ?? 0
        let tagCount = (try? getTagCount()) ?? 0
        let templateCount = (try? getTemplateCount()) ?? 0
        let hasExported = UserDefaults.standard.bool(forKey: "has_exported_data")

        for var achievement in Achievement.allAchievements {
            if unlocked[achievement.id] != nil { continue }

            let met: Bool
            switch achievement.id {
            case "first_record": met = totalCount >= 1
            case "records_10": met = totalCount >= 10
            case "records_50": met = totalCount >= 50
            case "records_100": met = totalCount >= 100
            case "records_500": met = totalCount >= 500
            case "records_1000": met = totalCount >= 1000
            case "streak_3": met = streak >= 3
            case "streak_7": met = streak >= 7
            case "streak_30": met = streak >= 30
            case "streak_100": met = streak >= 100
            case "streak_365": met = streak >= 365
            case "budget_set": met = budgetCount >= 1
            case "budget_under_3": met = budgetUnderCount >= 3
            case "first_tag": met = tagCount >= 1
            case "first_export": met = hasExported
            case "first_template": met = templateCount >= 1
            default: met = false
            }

            if met {
                let now = Date()
                unlocked[achievement.id] = now
                achievement.isUnlocked = true
                achievement.unlockedAt = now
                newlyUnlocked.append(achievement)
            }
        }

        if !newlyUnlocked.isEmpty {
            saveUnlockedSet(unlocked)
        }

        return newlyUnlocked
    }

    // MARK: - Data Queries

    private func getTotalTransactionCount() throws -> Int {
        try dbQueue.read { db in
            try Transaction.fetchCount(db)
        }
    }

    private func getCurrentStreak() throws -> Int {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT DISTINCT substr(created_at, 1, 10) as day
                FROM transactions
                ORDER BY day DESC
                """)

            let calendar = Calendar.current
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"

            var streak = 0
            var expectedDate = calendar.startOfDay(for: Date())

            for row in rows {
                guard let dayStr: String = row["day"],
                      let date = fmt.date(from: dayStr) else { continue }
                let day = calendar.startOfDay(for: date)
                if day == expectedDate {
                    streak += 1
                    expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
                } else if day < expectedDate {
                    break
                }
            }
            return streak
        }
    }

    private func getBudgetCount() throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM budgets") ?? 0
        }
    }

    private func getMonthsUnderBudget() throws -> Int {
        try dbQueue.read { db in
            let budgets = try Row.fetchAll(db, sql: "SELECT category_id, amount FROM budgets WHERE category_id IS NOT NULL")
            guard !budgets.isEmpty else { return 0 }

            let calendar = Calendar.current
            let now = Date()
            var underCount = 0

            for monthOffset in 1...6 {
                guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
                let year = calendar.component(.year, from: date)
                let month = calendar.component(.month, from: date)

                guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else { continue }

                let isoFmt = ISO8601DateFormatter()
                let startStr = isoFmt.string(from: start)
                let endStr = isoFmt.string(from: end)

                var allUnder = true
                for budget in budgets {
                    let catId: String = budget["category_id"]
                    let budgetAmount: Int64 = budget["amount"]
                    let spent = try Int64.fetchOne(db, sql: """
                        SELECT COALESCE(SUM(amount), 0) FROM transactions
                        WHERE category_id = ? AND type = 'expense'
                        AND created_at >= ? AND created_at < ?
                        """, arguments: [catId, startStr, endStr]) ?? 0
                    if spent > budgetAmount {
                        allUnder = false
                        break
                    }
                }
                if allUnder { underCount += 1 }
            }
            return underCount
        }
    }

    private func getTagCount() throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM tags") ?? 0
        }
    }

    private func getTemplateCount() throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM transaction_templates") ?? 0
        }
    }

    // MARK: - Storage

    private func loadUnlockedSet() -> [String: Date] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let dict = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        return dict
    }

    private func saveUnlockedSet(_ dict: [String: Date]) {
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
