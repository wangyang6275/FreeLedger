import Foundation
import GRDB

struct BackupReminderService {
    private let dbQueue: DatabaseQueue
    private let settingsDAO: SettingsDAO

    nonisolated(unsafe) private static let isoFormatter = ISO8601DateFormatter()

    init(dbQueue: DatabaseQueue, settingsDAO: SettingsDAO) {
        self.dbQueue = dbQueue
        self.settingsDAO = settingsDAO
    }

    enum ReminderType {
        case firstBackup(count: Int)
        case periodicBackup
        case none
    }

    func checkReminder() -> ReminderType {
        let lastBackupDate = try? settingsDAO.get(key: "last_backup_date")
        let transactionCount = (try? dbQueue.read { db in
            try Transaction.fetchCount(db)
        }) ?? 0

        if lastBackupDate == nil {
            if transactionCount >= 50 {
                return .firstBackup(count: transactionCount)
            }
            return .none
        }

        if let dateString = lastBackupDate,
           let date = Self.isoFormatter.date(from: dateString) {
            let daysSinceBackup = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            if daysSinceBackup >= 30 {
                return .periodicBackup
            }
        }

        return .none
    }
}
