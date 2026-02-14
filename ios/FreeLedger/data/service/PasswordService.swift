import Foundation
import CryptoKit
import Security

struct PasswordService {
    private static let keychainServiceName = "com.freeledger.app.password"
    private static let hashKey = "password_hash"
    private static let saltKey = "password_salt"

    func isPasswordSet() -> Bool {
        return readKeychain(key: Self.hashKey) != nil
    }

    func setPassword(_ password: String) -> Bool {
        let salt = generateSalt()
        let hash = hashPassword(password, salt: salt)
        let savedHash = saveKeychain(key: Self.hashKey, value: hash)
        let savedSalt = saveKeychain(key: Self.saltKey, value: salt)
        return savedHash && savedSalt
    }

    func verifyPassword(_ password: String) -> Bool {
        guard let storedHash = readKeychain(key: Self.hashKey),
              let storedSalt = readKeychain(key: Self.saltKey) else {
            return false
        }
        let hash = hashPassword(password, salt: storedSalt)
        return hash == storedHash
    }

    func removePassword() -> Bool {
        let removedHash = deleteKeychain(key: Self.hashKey)
        let removedSalt = deleteKeychain(key: Self.saltKey)
        return removedHash && removedSalt
    }

    // MARK: - Private

    private func generateSalt() -> String {
        let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64EncodedString()
    }

    private func hashPassword(_ password: String, salt: String) -> String {
        let input = password + salt
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain

    private func saveKeychain(key: String, value: String) -> Bool {
        deleteKeychain(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainServiceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func readKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainServiceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private func deleteKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainServiceName,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
