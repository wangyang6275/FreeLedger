import Foundation

@Observable
final class AchievementViewModel {
    private let achievementService: AchievementService

    var achievements: [Achievement] = []
    var newlyUnlocked: [Achievement] = []
    var showCongrats = false

    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var totalCount: Int {
        achievements.count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }

    init(achievementService: AchievementService) {
        self.achievementService = achievementService
    }

    func loadData() {
        let newOnes = achievementService.evaluateAll()
        achievements = achievementService.getAchievements()
        if !newOnes.isEmpty {
            newlyUnlocked = newOnes
            showCongrats = true
        }
    }

    func dismissCongrats() {
        showCongrats = false
        newlyUnlocked = []
    }
}
