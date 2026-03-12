import Foundation

protocol ReminderRepositoryProtocol {
    func getAll() throws -> [Reminder]
    func getEnabled() throws -> [Reminder]
    func getById(_ id: String) throws -> Reminder?
    func create(_ reminder: Reminder) throws
    func update(_ reminder: Reminder) throws
    func delete(id: String) throws
}

final class ReminderRepository: ReminderRepositoryProtocol {
    private let dao: ReminderDAO

    init(dao: ReminderDAO) {
        self.dao = dao
    }

    func getAll() throws -> [Reminder] {
        try dao.getAll()
    }

    func getEnabled() throws -> [Reminder] {
        try dao.getEnabled()
    }

    func getById(_ id: String) throws -> Reminder? {
        try dao.getById(id)
    }

    func create(_ reminder: Reminder) throws {
        try dao.insert(reminder)
    }

    func update(_ reminder: Reminder) throws {
        try dao.update(reminder)
    }

    func delete(id: String) throws {
        try dao.delete(id: id)
    }
}
