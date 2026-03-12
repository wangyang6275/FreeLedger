import Foundation
import CryptoKit

struct BackupData: Codable {
    let version: Int
    let createdAt: String
    let checksum: String
    let transactions: [Transaction]
    let categories: [Category]
    let tags: [Tag]
    let transactionTags: [TransactionTag]

    enum CodingKeys: String, CodingKey {
        case version
        case createdAt = "created_at"
        case checksum
        case transactions
        case categories
        case tags
        case transactionTags = "transaction_tags"
    }

    static func generateChecksum(transactions: [Transaction], categories: [Category], tags: [Tag], transactionTags: [TransactionTag]) -> String {
        let counts = "\(transactions.count)|\(categories.count)|\(tags.count)|\(transactionTags.count)"
        let ids = transactions.map(\.id).sorted().joined(separator: ",")
        let raw = counts + "|" + ids
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
