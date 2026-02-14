import Foundation
import GRDB

struct CSVExportField: Identifiable, Hashable {
    let id: String
    let labelKey: String
    var isSelected: Bool

    static func defaultFields() -> [CSVExportField] {
        [
            CSVExportField(id: "date", labelKey: "csv_field_date", isSelected: true),
            CSVExportField(id: "amount", labelKey: "csv_field_amount", isSelected: true),
            CSVExportField(id: "type", labelKey: "csv_field_type", isSelected: true),
            CSVExportField(id: "category", labelKey: "csv_field_category", isSelected: true),
            CSVExportField(id: "note", labelKey: "csv_field_note", isSelected: true),
            CSVExportField(id: "tags", labelKey: "csv_field_tags", isSelected: true),
        ]
    }
}

struct CSVExportService {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func exportCSV(fields: [CSVExportField]) throws -> Data {
        let selectedFields = fields.filter(\.isSelected)
        guard !selectedFields.isEmpty else { return Data() }

        let (transactions, categoryDict, tagMap) = try dbQueue.read { db -> ([Transaction], [String: Category], [String: [Tag]]) in
            let txs = try Transaction.order(Column("created_at").desc).fetchAll(db)
            let cats = try Category.fetchAll(db)
            let catDict = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })

            let allTags = try Tag.fetchAll(db)
            let tagDict = Dictionary(uniqueKeysWithValues: allTags.map { ($0.id, $0) })
            let ttRows = try TransactionTag.fetchAll(db)

            var tagMap: [String: [Tag]] = [:]
            for tt in ttRows {
                if let tag = tagDict[tt.tagId] {
                    tagMap[tt.transactionId, default: []].append(tag)
                }
            }

            return (txs, catDict, tagMap)
        }

        var csv = ""

        // Header
        let headers = selectedFields.map { field in
            headerName(for: field.id)
        }
        csv += headers.joined(separator: ",") + "\n"

        // Rows
        for tx in transactions {
            let values = selectedFields.map { field in
                csvValue(for: field.id, transaction: tx, categoryDict: categoryDict, tagMap: tagMap)
            }
            csv += values.joined(separator: ",") + "\n"
        }

        return Data(csv.utf8)
    }

    private func headerName(for fieldId: String) -> String {
        switch fieldId {
        case "date": return "Date"
        case "amount": return "Amount"
        case "type": return "Type"
        case "category": return "Category"
        case "note": return "Note"
        case "tags": return "Tags"
        default: return fieldId
        }
    }

    private func csvValue(for fieldId: String, transaction: Transaction, categoryDict: [String: Category], tagMap: [String: [Tag]]) -> String {
        switch fieldId {
        case "date":
            return escapeCSV(transaction.createdAt)
        case "amount":
            let value = Double(transaction.amount) / 100.0
            return String(format: "%.2f", value)
        case "type":
            return transaction.type
        case "category":
            let cat = categoryDict[transaction.categoryId]
            let name: String
            if let cat = cat {
                if cat.isCustom {
                    name = cat.nameKey
                } else {
                    name = L(cat.nameKey)
                }
            } else {
                name = "—"
            }
            return escapeCSV(name)
        case "note":
            return escapeCSV(transaction.note ?? "")
        case "tags":
            let tags = tagMap[transaction.id] ?? []
            let names = tags.map(\.name).joined(separator: "; ")
            return escapeCSV(names)
        default:
            return ""
        }
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
