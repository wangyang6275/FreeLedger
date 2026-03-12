import Foundation
import os

/// 统一日志服务，基于 os.Logger
/// 使用方式：AppLogger.data.error("xxx", error)
enum AppLogger {
    /// 数据层日志（数据库、DAO）
    static let data = Logger(subsystem: "com.colorfuledger.app", category: "Data")
    /// UI 层日志（ViewModel、View）
    static let ui = Logger(subsystem: "com.colorfuledger.app", category: "UI")
    /// 服务层日志（备份、通知、Widget）
    static let service = Logger(subsystem: "com.colorfuledger.app", category: "Service")
}
