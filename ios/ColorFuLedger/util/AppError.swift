import Foundation

enum AppError: Error, LocalizedError {
    case databaseError(String)
    case backupExportFailed(String)
    case backupImportFailed(String)
    case backupChecksumMismatch
    case invalidInput(String)
    case storageInsufficient

    var errorDescription: String? {
        switch self {
        case .databaseError(let msg): return msg
        case .backupExportFailed(let msg): return msg
        case .backupImportFailed(let msg): return msg
        case .backupChecksumMismatch: return L("error_checksum_mismatch")
        case .invalidInput(let msg): return msg
        case .storageInsufficient: return L("error_storage_insufficient")
        }
    }
}
