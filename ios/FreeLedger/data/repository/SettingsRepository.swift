import Foundation

protocol SettingsRepositoryProtocol {
    func getCurrency() throws -> String
    func setCurrency(_ code: String) throws
    func get(key: String) throws -> String?
    func set(key: String, value: String) throws
}

final class SettingsRepository: SettingsRepositoryProtocol {
    private let dao: SettingsDAO

    init(dao: SettingsDAO) {
        self.dao = dao
    }

    func getCurrency() throws -> String {
        try dao.get(key: "currency") ?? "CNY"
    }

    func setCurrency(_ code: String) throws {
        try dao.set(key: "currency", value: code)
    }

    func get(key: String) throws -> String? {
        try dao.get(key: key)
    }

    func set(key: String, value: String) throws {
        try dao.set(key: key, value: value)
    }
}
