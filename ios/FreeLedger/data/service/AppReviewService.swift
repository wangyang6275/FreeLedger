import Foundation
import StoreKit
import UIKit

/// 应用评分引导服务
/// 在用户完成正向操作后，智能地引导用户评分
@MainActor
final class AppReviewService {
    static let shared = AppReviewService()

    private let userDefaults = UserDefaults.standard

    // UserDefaults Keys
    private enum Keys {
        static let transactionCount = "app_review_transaction_count"
        static let consecutiveDaysUsed = "app_review_consecutive_days"
        static let lastUsedDate = "app_review_last_used_date"
        static let lastReviewRequestDate = "app_review_last_request_date"
        static let hasUserDeclined = "app_review_user_declined"
        static let hasUserRated = "app_review_user_rated"
        static let csvExportCount = "app_review_csv_export_count"
        static let reminderCreatedCount = "app_review_reminder_count"
    }

    // 触发条件阈值
    private enum Thresholds {
        static let transactionCount = 5        // 完成 5 笔交易
        static let consecutiveDays = 7         // 连续使用 7 天
        static let csvExportCount = 1          // 导出 1 次 CSV
        static let reminderCount = 1           // 创建 1 个提醒
        static let daysBetweenRequests = 30    // 两次请求间隔至少 30 天
        static let daysAfterDecline = 90       // 用户拒绝后 90 天再问
    }

    private init() {
        updateDailyUsage()
    }

    // MARK: - 公开方法

    /// 记录交易创建
    func recordTransactionCreated() {
        incrementCounter(for: Keys.transactionCount)
        checkAndRequestReview()
    }

    /// 记录 CSV 导出
    func recordCSVExported() {
        incrementCounter(for: Keys.csvExportCount)
        checkAndRequestReview()
    }

    /// 记录提醒创建
    func recordReminderCreated() {
        incrementCounter(for: Keys.reminderCreatedCount)
        checkAndRequestReview()
    }

    /// 用户主动评分（从设置页面）
    func userRequestedReview() {
        requestReview(forced: true)
    }

    /// 用户表示已经评分
    func markAsRated() {
        userDefaults.set(true, forKey: Keys.hasUserRated)
    }

    // MARK: - 私有方法

    /// 更新每日使用记录
    private func updateDailyUsage() {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastUsedDate = userDefaults.object(forKey: Keys.lastUsedDate) as? Date {
            let lastUsedDay = Calendar.current.startOfDay(for: lastUsedDate)
            let daysDifference = Calendar.current.dateComponents([.day], from: lastUsedDay, to: today).day ?? 0

            if daysDifference == 1 {
                // 连续使用
                let currentDays = userDefaults.integer(forKey: Keys.consecutiveDaysUsed)
                userDefaults.set(currentDays + 1, forKey: Keys.consecutiveDaysUsed)
            } else if daysDifference > 1 {
                // 中断了，重新计数
                userDefaults.set(1, forKey: Keys.consecutiveDaysUsed)
            }
            // daysDifference == 0 表示今天已经记录过了
        } else {
            // 第一次使用
            userDefaults.set(1, forKey: Keys.consecutiveDaysUsed)
        }

        userDefaults.set(today, forKey: Keys.lastUsedDate)
    }

    /// 增加计数器
    private func incrementCounter(for key: String) {
        let current = userDefaults.integer(forKey: key)
        userDefaults.set(current + 1, forKey: key)
    }

    /// 检查是否应该请求评分
    private func checkAndRequestReview() {
        // 如果用户已经评分，不再请求
        if userDefaults.bool(forKey: Keys.hasUserRated) {
            return
        }

        // 检查是否满足触发条件
        guard shouldRequestReview() else {
            return
        }

        // 检查时间间隔
        guard canRequestReviewNow() else {
            return
        }

        requestReview(forced: false)
    }

    /// 判断是否满足触发条件
    private func shouldRequestReview() -> Bool {
        let transactionCount = userDefaults.integer(forKey: Keys.transactionCount)
        let consecutiveDays = userDefaults.integer(forKey: Keys.consecutiveDaysUsed)
        let csvExportCount = userDefaults.integer(forKey: Keys.csvExportCount)
        let reminderCount = userDefaults.integer(forKey: Keys.reminderCreatedCount)

        // 满足任一条件即可
        return transactionCount >= Thresholds.transactionCount ||
               consecutiveDays >= Thresholds.consecutiveDays ||
               csvExportCount >= Thresholds.csvExportCount ||
               reminderCount >= Thresholds.reminderCount
    }

    /// 检查是否可以现在请求评分（时间间隔）
    private func canRequestReviewNow() -> Bool {
        guard let lastRequestDate = userDefaults.object(forKey: Keys.lastReviewRequestDate) as? Date else {
            return true
        }

        let requiredDays = userDefaults.bool(forKey: Keys.hasUserDeclined)
            ? Thresholds.daysAfterDecline
            : Thresholds.daysBetweenRequests

        let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
        return daysSinceLastRequest >= requiredDays
    }

    /// 请求评分
    private func requestReview(forced: Bool) {
        // 记录请求时间
        userDefaults.set(Date(), forKey: Keys.lastReviewRequestDate)

        // 使用 StoreKit 请求评分（已在 @MainActor 上，无需 DispatchQueue）
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    // MARK: - 调试和测试方法

    #if DEBUG
    /// 重置所有统计数据（仅用于测试）
    func resetAllStats() {
        userDefaults.removeObject(forKey: Keys.transactionCount)
        userDefaults.removeObject(forKey: Keys.consecutiveDaysUsed)
        userDefaults.removeObject(forKey: Keys.lastUsedDate)
        userDefaults.removeObject(forKey: Keys.lastReviewRequestDate)
        userDefaults.removeObject(forKey: Keys.hasUserDeclined)
        userDefaults.removeObject(forKey: Keys.hasUserRated)
        userDefaults.removeObject(forKey: Keys.csvExportCount)
        userDefaults.removeObject(forKey: Keys.reminderCreatedCount)
    }

    /// 获取当前统计信息（仅用于测试）
    func getCurrentStats() -> [String: Any] {
        return [
            "transactions": userDefaults.integer(forKey: Keys.transactionCount),
            "consecutiveDays": userDefaults.integer(forKey: Keys.consecutiveDaysUsed),
            "csvExports": userDefaults.integer(forKey: Keys.csvExportCount),
            "reminders": userDefaults.integer(forKey: Keys.reminderCreatedCount),
            "hasRated": userDefaults.bool(forKey: Keys.hasUserRated),
            "hasDeclined": userDefaults.bool(forKey: Keys.hasUserDeclined),
            "lastRequestDate": userDefaults.object(forKey: Keys.lastReviewRequestDate) as? Date ?? "Never"
        ]
    }
    #endif
}
