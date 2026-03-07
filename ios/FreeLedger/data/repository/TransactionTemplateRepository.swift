import Foundation

protocol TransactionTemplateRepositoryProtocol {
    func getAll() throws -> [TransactionTemplate]
    func getById(_ id: String) throws -> TransactionTemplate?
    func insert(_ template: TransactionTemplate) throws
    func update(_ template: TransactionTemplate) throws
    func delete(id: String) throws
}

final class TransactionTemplateRepository: TransactionTemplateRepositoryProtocol {
    private let dao: TransactionTemplateDAO

    init(dao: TransactionTemplateDAO) {
        self.dao = dao
    }

    func getAll() throws -> [TransactionTemplate] {
        try dao.getAll()
    }

    func getById(_ id: String) throws -> TransactionTemplate? {
        try dao.getById(id)
    }

    func insert(_ template: TransactionTemplate) throws {
        try dao.insert(template)
    }

    func update(_ template: TransactionTemplate) throws {
        try dao.update(template)
    }

    func delete(id: String) throws {
        try dao.delete(id: id)
    }
}
