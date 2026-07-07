import Foundation
import CryptoKit
import SwiftUI

/// The single source of truth. Holds all items, persists them encrypted, and
/// manages the vault lock state.
@MainActor
final class Store: ObservableObject {
    @Published private(set) var items: [Item] = []
    /// True once the user has passed Touch ID for this session.
    @Published var vaultUnlocked = false

    private let key = Crypto.masterKey()
    private let fileURL: URL

    init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pocket", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        self.fileURL = support.appendingPathComponent("store.dat")
        load()
    }

    // MARK: - Derived collections

    var openItems: [Item] { items.filter { !$0.locked } }
    var vaultItems: [Item] { items.filter { $0.locked } }

    // MARK: - Mutations

    func add(_ item: Item) {
        items.insert(item, at: 0)
        save()
    }

    func update(_ item: Item) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        save()
    }

    func delete(_ item: Item) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func toggleLock(_ item: Item) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].locked.toggle()
        save()
    }

    // MARK: - Vault

    func unlockVault() async -> Bool {
        if vaultUnlocked { return true }
        let ok = await Biometrics.authenticate(reason: "Kasayı açmak için kimliğini doğrula")
        if ok { vaultUnlocked = true }
        return ok
    }

    func lockVault() {
        vaultUnlocked = false
    }

    // MARK: - Persistence

    private func load() {
        guard let blob = try? Data(contentsOf: fileURL) else { return }
        do {
            let plain = try Crypto.decrypt(blob, key: key)
            items = try JSONDecoder().decode([Item].self, from: plain)
        } catch {
            NSLog("pocket: failed to load store: \(error)")
        }
    }

    private func save() {
        do {
            let plain = try JSONEncoder().encode(items)
            let blob = try Crypto.encrypt(plain, key: key)
            try blob.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            NSLog("pocket: failed to save store: \(error)")
        }
    }
}
