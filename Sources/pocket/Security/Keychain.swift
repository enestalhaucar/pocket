import Foundation
import Security

/// Stores exactly ONE item in the login keychain: pocket's master encryption key.
/// Individual notes/secrets are never written to the keychain — they live encrypted
/// in pocket's own store file — so nothing gets duplicated into Keychain Access.
enum Keychain {
    private static let service = "com.enestalhaucar.pocket"
    private static let account = "master-key"

    static func loadKey() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func saveKey(_ data: Data) -> Bool {
        // Remove any previous value first so SecItemAdd never fails with duplicate.
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)

        var attributes = base
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }
}
