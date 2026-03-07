import Foundation
import GRDB
import UIKit

enum PDFExportRange {
    case month(year: Int, month: Int)
    case year(year: Int)
    case all
}

struct PDFExportService {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    // MARK: - Public

    func exportPDF(range: PDFExportRange, currencyCode: String) throws -> Data {
        let (transactions, categoryDict, tagMap) = try fetchData(range: range)
        let title = reportTitle(for: range)
        let summary = computeSummary(transactions)
        let expenseBreakdown = computeCategoryBreakdown(transactions, categoryDict: categoryDict, type: "expense")
        let incomeBreakdown = computeCategoryBreakdown(transactions, categoryDict: categoryDict, type: "income")

        return renderPDF(
            title: title,
            range: range,
            transactions: transactions,
            categoryDict: categoryDict,
            tagMap: tagMap,
            summary: summary,
            expenseBreakdown: expenseBreakdown,
            incomeBreakdown: incomeBreakdown,
            currencyCode: currencyCode
        )
    }

    // MARK: - Data Fetching

    private func fetchData(range: PDFExportRange) throws -> ([Transaction], [String: Category], [String: [Tag]]) {
        try dbQueue.read { db in
            let txs: [Transaction]
            switch range {
            case .month(let year, let month):
                let calendar = Calendar.current
                guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else {
                    txs = []
                    break
                }
                let fmt = ISO8601DateFormatter()
                txs = try Transaction
                    .filter(Transaction.Columns.createdAt >= fmt.string(from: start))
                    .filter(Transaction.Columns.createdAt < fmt.string(from: end))
                    .order(Transaction.Columns.createdAt.desc)
                    .fetchAll(db)
            case .year(let year):
                let calendar = Calendar.current
                guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                      let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
                    txs = []
                    break
                }
                let fmt = ISO8601DateFormatter()
                txs = try Transaction
                    .filter(Transaction.Columns.createdAt >= fmt.string(from: start))
                    .filter(Transaction.Columns.createdAt < fmt.string(from: end))
                    .order(Transaction.Columns.createdAt.desc)
                    .fetchAll(db)
            case .all:
                txs = try Transaction.order(Transaction.Columns.createdAt.desc).fetchAll(db)
            }

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
    }

    // MARK: - Summary

    private struct Summary {
        let totalExpense: Int64
        let totalIncome: Int64
        var balance: Int64 { totalIncome - totalExpense }
        let count: Int
    }

    private func computeSummary(_ transactions: [Transaction]) -> Summary {
        var expense: Int64 = 0
        var income: Int64 = 0
        for tx in transactions {
            if tx.type == TransactionType.expense.rawValue {
                expense += tx.amount
            } else {
                income += tx.amount
            }
        }
        return Summary(totalExpense: expense, totalIncome: income, count: transactions.count)
    }

    private struct BreakdownItem {
        let categoryName: String
        let total: Int64
        let percentage: Double
    }

    private func computeCategoryBreakdown(_ transactions: [Transaction], categoryDict: [String: Category], type: String) -> [BreakdownItem] {
        var totals: [String: Int64] = [:]
        for tx in transactions where tx.type == type {
            totals[tx.categoryId, default: 0] += tx.amount
        }
        let grandTotal = totals.values.reduce(0, +)
        guard grandTotal > 0 else { return [] }

        return totals
            .sorted { $0.value > $1.value }
            .map { (catId, total) in
                let cat = categoryDict[catId]
                let name: String
                if let c = cat {
                    name = c.isCustom ? c.nameKey : L(c.nameKey)
                } else {
                    name = "—"
                }
                let pct = Double(total) / Double(grandTotal) * 100.0
                return BreakdownItem(categoryName: name, total: total, percentage: pct)
            }
    }

    // MARK: - Title

    private func reportTitle(for range: PDFExportRange) -> String {
        switch range {
        case .month(let year, let month):
            let comps = DateComponents(year: year, month: month, day: 1)
            let f = DateFormatter()
            f.locale = LanguageManager.locale
            f.setLocalizedDateFormatFromTemplate("yyyy MMMM")
            if let date = Calendar.current.date(from: comps) {
                return f.string(from: date)
            }
            return "\(year)-\(month)"
        case .year(let year):
            return "\(year)"
        case .all:
            return L("pdf_range_all")
        }
    }

    // MARK: - PDF Rendering

    private func renderPDF(
        title: String,
        range: PDFExportRange,
        transactions: [Transaction],
        categoryDict: [String: Category],
        tagMap: [String: [Tag]],
        summary: Summary,
        expenseBreakdown: [BreakdownItem],
        incomeBreakdown: [BreakdownItem],
        currencyCode: String
    ) -> Data {
        let pageWidth: CGFloat = 595.28  // A4
        let pageHeight: CGFloat = 841.89
        let margin: CGFloat = 40
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            var y: CGFloat = 0

            func beginNewPage() {
                context.beginPage()
                y = margin
            }

            func ensureSpace(_ height: CGFloat) {
                if y + height > pageHeight - margin {
                    beginNewPage()
                }
            }

            // -- Title page --
            beginNewPage()

            // App title
            let appTitleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor(red: 0.18, green: 0.20, blue: 0.21, alpha: 1)
            ]
            let appTitle = "FreeLedger"
            appTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: appTitleAttr)
            y += 34

            // Report period
            let periodAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor(red: 0.39, green: 0.43, blue: 0.45, alpha: 1)
            ]
            let periodText = "\(L("pdf_report_title")) — \(title)"
            periodText.draw(at: CGPoint(x: margin, y: y), withAttributes: periodAttr)
            y += 26

            // Generated date
            let dateAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor(red: 0.70, green: 0.74, blue: 0.76, alpha: 1)
            ]
            let genDateFmt = DateFormatter()
            genDateFmt.dateStyle = .long
            genDateFmt.locale = LanguageManager.locale
            let genText = "\(L("pdf_generated")) \(genDateFmt.string(from: Date()))"
            genText.draw(at: CGPoint(x: margin, y: y), withAttributes: dateAttr)
            y += 30

            // Divider
            drawDivider(context: context.cgContext, y: y, x: margin, width: contentWidth)
            y += 16

            // -- Summary section --
            drawSectionTitle(L("pdf_summary"), at: CGPoint(x: margin, y: y), context: context.cgContext)
            y += 28

            let summaryItems: [(String, String, UIColor)] = [
                (L("pdf_total_income"), formatAmount(summary.totalIncome, currencyCode: currencyCode), UIColor(red: 0, green: 0.72, blue: 0.58, alpha: 1)),
                (L("pdf_total_expense"), formatAmount(summary.totalExpense, currencyCode: currencyCode), UIColor(red: 0.88, green: 0.44, blue: 0.33, alpha: 1)),
                (L("pdf_balance"), formatAmount(summary.balance, currencyCode: currencyCode), UIColor(red: 0.18, green: 0.20, blue: 0.21, alpha: 1)),
                (L("pdf_transaction_count"), "\(summary.count)", UIColor(red: 0.39, green: 0.43, blue: 0.45, alpha: 1)),
            ]

            for (label, value, color) in summaryItems {
                ensureSpace(22)
                let labelAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                    .foregroundColor: UIColor(red: 0.39, green: 0.43, blue: 0.45, alpha: 1)
                ]
                label.draw(at: CGPoint(x: margin + 8, y: y), withAttributes: labelAttr)

                let valueAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: color
                ]
                let valueSize = (value as NSString).size(withAttributes: valueAttr)
                value.draw(at: CGPoint(x: pageWidth - margin - valueSize.width, y: y), withAttributes: valueAttr)
                y += 22
            }
            y += 12

            // -- Category breakdown (expense) --
            if !expenseBreakdown.isEmpty {
                drawDivider(context: context.cgContext, y: y, x: margin, width: contentWidth)
                y += 16
                drawSectionTitle(L("pdf_expense_breakdown"), at: CGPoint(x: margin, y: y), context: context.cgContext)
                y += 28
                y = drawBreakdownTable(expenseBreakdown, startY: y, margin: margin, contentWidth: contentWidth, currencyCode: currencyCode, context: context, pageHeight: pageHeight)
                y += 12
            }

            // -- Category breakdown (income) --
            if !incomeBreakdown.isEmpty {
                ensureSpace(50)
                drawDivider(context: context.cgContext, y: y, x: margin, width: contentWidth)
                y += 16
                drawSectionTitle(L("pdf_income_breakdown"), at: CGPoint(x: margin, y: y), context: context.cgContext)
                y += 28
                y = drawBreakdownTable(incomeBreakdown, startY: y, margin: margin, contentWidth: contentWidth, currencyCode: currencyCode, context: context, pageHeight: pageHeight)
                y += 12
            }

            // -- Transaction list --
            if !transactions.isEmpty {
                ensureSpace(50)
                drawDivider(context: context.cgContext, y: y, x: margin, width: contentWidth)
                y += 16
                drawSectionTitle(L("pdf_transactions"), at: CGPoint(x: margin, y: y), context: context.cgContext)
                y += 28

                // Table header
                y = drawTransactionHeader(y: y, margin: margin, contentWidth: contentWidth, context: context.cgContext)

                let dateFmt = DateFormatter()
                dateFmt.dateStyle = .short
                dateFmt.timeStyle = .short
                dateFmt.locale = LanguageManager.locale

                let isoFmt = ISO8601DateFormatter()

                for tx in transactions {
                    let rowHeight: CGFloat = 20
                    if y + rowHeight > pageHeight - margin {
                        beginNewPage()
                        y = drawTransactionHeader(y: y, margin: margin, contentWidth: contentWidth, context: context.cgContext)
                    }

                    let cat = categoryDict[tx.categoryId]
                    let catName: String
                    if let c = cat {
                        catName = c.isCustom ? c.nameKey : L(c.nameKey)
                    } else {
                        catName = "—"
                    }

                    let dateStr: String
                    if let d = isoFmt.date(from: tx.createdAt) {
                        dateStr = dateFmt.string(from: d)
                    } else {
                        dateStr = String(tx.createdAt.prefix(10))
                    }

                    let amountStr = formatAmount(tx.amount, currencyCode: currencyCode)
                    let isExpense = tx.type == TransactionType.expense.rawValue
                    let amountColor = isExpense
                        ? UIColor(red: 0.88, green: 0.44, blue: 0.33, alpha: 1)
                        : UIColor(red: 0, green: 0.72, blue: 0.58, alpha: 1)
                    let prefix = isExpense ? "-" : "+"

                    let cellFont = UIFont.systemFont(ofSize: 10, weight: .regular)
                    let cellAttr: [NSAttributedString.Key: Any] = [
                        .font: cellFont,
                        .foregroundColor: UIColor(red: 0.18, green: 0.20, blue: 0.21, alpha: 1)
                    ]

                    // Date column
                    let dateRect = CGRect(x: margin, y: y, width: contentWidth * 0.28, height: rowHeight)
                    drawClipped(dateStr, in: dateRect, attributes: cellAttr)

                    // Category column
                    let catRect = CGRect(x: margin + contentWidth * 0.28, y: y, width: contentWidth * 0.22, height: rowHeight)
                    drawClipped(catName, in: catRect, attributes: cellAttr)

                    // Note column
                    let noteRect = CGRect(x: margin + contentWidth * 0.50, y: y, width: contentWidth * 0.28, height: rowHeight)
                    drawClipped(tx.note ?? "", in: noteRect, attributes: cellAttr)

                    // Amount column (right-aligned)
                    let amountAttr: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                        .foregroundColor: amountColor
                    ]
                    let fullAmount = "\(prefix)\(amountStr)"
                    let amountSize = (fullAmount as NSString).size(withAttributes: amountAttr)
                    fullAmount.draw(at: CGPoint(x: pageWidth - margin - amountSize.width, y: y + 2), withAttributes: amountAttr)

                    y += rowHeight
                }
            }

            // -- Footer on last page --
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor(red: 0.70, green: 0.74, blue: 0.76, alpha: 1)
            ]
            let footer = "FreeLedger · \(genDateFmt.string(from: Date()))"
            let footerSize = (footer as NSString).size(withAttributes: footerAttr)
            footer.draw(at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - margin + 10), withAttributes: footerAttr)
        }
    }

    // MARK: - Drawing Helpers

    private func drawDivider(context: CGContext, y: CGFloat, x: CGFloat, width: CGFloat) {
        context.setStrokeColor(UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1).cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x + width, y: y))
        context.strokePath()
    }

    private func drawSectionTitle(_ title: String, at point: CGPoint, context: CGContext) {
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: UIColor(red: 0.18, green: 0.20, blue: 0.21, alpha: 1)
        ]
        title.draw(at: point, withAttributes: attr)
    }

    private func drawBreakdownTable(
        _ items: [BreakdownItem],
        startY: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        currencyCode: String,
        context: UIGraphicsPDFRendererContext,
        pageHeight: CGFloat
    ) -> CGFloat {
        var y = startY
        let rowHeight: CGFloat = 20

        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor(red: 0.18, green: 0.20, blue: 0.21, alpha: 1)
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor(red: 0.39, green: 0.43, blue: 0.45, alpha: 1)
        ]
        let pctAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor(red: 0.70, green: 0.74, blue: 0.76, alpha: 1)
        ]

        let pageWidth = margin * 2 + contentWidth

        for item in items {
            if y + rowHeight > pageHeight - margin {
                context.beginPage()
                y = margin
            }

            item.categoryName.draw(at: CGPoint(x: margin + 8, y: y), withAttributes: labelAttr)

            let pctStr = String(format: "%.1f%%", item.percentage)
            let pctSize = (pctStr as NSString).size(withAttributes: pctAttr)
            pctStr.draw(at: CGPoint(x: pageWidth - margin - pctSize.width, y: y), withAttributes: pctAttr)

            let amtStr = formatAmount(item.total, currencyCode: currencyCode)
            let amtSize = (amtStr as NSString).size(withAttributes: valueAttr)
            amtStr.draw(at: CGPoint(x: pageWidth - margin - pctSize.width - 12 - amtSize.width, y: y), withAttributes: valueAttr)

            y += rowHeight
        }

        return y
    }

    private func drawTransactionHeader(y: CGFloat, margin: CGFloat, contentWidth: CGFloat, context: CGContext) -> CGFloat {
        let headerAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor(red: 0.39, green: 0.43, blue: 0.45, alpha: 1)
        ]

        L("pdf_col_date").draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttr)
        L("pdf_col_category").draw(at: CGPoint(x: margin + contentWidth * 0.28, y: y), withAttributes: headerAttr)
        L("pdf_col_note").draw(at: CGPoint(x: margin + contentWidth * 0.50, y: y), withAttributes: headerAttr)

        let amtHeader = L("pdf_col_amount")
        let amtSize = (amtHeader as NSString).size(withAttributes: headerAttr)
        let pageWidth = margin * 2 + contentWidth
        amtHeader.draw(at: CGPoint(x: pageWidth - margin - amtSize.width, y: y), withAttributes: headerAttr)

        var newY = y + 18
        context.setStrokeColor(UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1).cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: newY))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: newY))
        context.strokePath()
        newY += 6
        return newY
    }

    private func drawClipped(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.clip(to: rect)
        text.draw(at: CGPoint(x: rect.origin.x, y: rect.origin.y + 2), withAttributes: attributes)
        context?.restoreGState()
    }

    private func formatAmount(_ cents: Int64, currencyCode: String) -> String {
        AmountFormatter.format(cents, currencyCode: currencyCode)
    }
}
