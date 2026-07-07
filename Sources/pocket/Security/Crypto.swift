import Foundation
import CryptoKit

/// AES-GCM encryption for the whole store, keyed by a master key kept in the keychain.
enum Crypto {
    /// Fetches the master key, creating and persisting one on first launch.
    static func masterKey() -> SymmetricKey {
        if let data = Keychain.loadKey(), data.count == 32 {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        let raw = key.withUnsafeBytes { Data($0) }
        Keychain.saveKey(raw)
        return key
    }

    static func encrypt(_ plaintext: Data, key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw CocoaError(.coderInvalidValue)
        }
        return combined
    }

    static func decrypt(_ ciphertext: Data, key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(box, using: key)
    }
}
