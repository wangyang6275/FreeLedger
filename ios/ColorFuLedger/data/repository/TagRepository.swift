import Foundation
import GRDB

protocol TagRepositoryProtocol {
    func getAll() throws -> [Tag]
    func getById(_ id: String) throws -> Tag?
    func create(_ tag: Tag) throws
    func update(_ tag: Tag) throws
    func delete(id: String) throws
    func getTagsForTransaction(transactionId: String) throws -> [Tag]
    func getTransactionCountPerTag() throws -> [String: Int]
    func getTransactionsForTag(tagId: String) throws -> [Transaction]
    func getTagExpenseBreakdown(year: Int, month: Int) throws -> [TagExpenseBreakdown]
}

final class TagRepository: TagRepositoryProtocol {
    private let dao: TagDAO

    init(dao: TagDAO) {
        self.dao = dao
    }

    func getAll() throws -> [Tag] {
        try dao.getAll()
    }

    func getById(_ id: String) throws -> Tag? {
        try dao.getById(id)
    }

    func create(_ tag: Tag) throws {
        try dao.insert(tag)
    }

    func update(_ tag: Tag) throws {
        try dao.update(tag)
    }

    func delete(id: String) throws {
        try dao.delete(id: id)
    }

    func getTagsForTransaction(transactionId: String) throws -> [Tag] {
        try dao.getTagsForTransaction(transactionId: transactionId)
    }

    func getTransactionCountPerTag() throws -> [String: Int] {
        try dao.getTransactionCountPerTag()
    }

    func getTransactionsForTag(tagId: String) throws -> [Transaction] {
        try dao.getTransactionsForTag(tagId: tagId)
    }

    func getTagExpenseBreakdown(year: Int, month: Int) throws -> [TagExpenseBreakdown] {
        try dao.getTagExpenseBreakdown(year: year, month: month)
    }
}
