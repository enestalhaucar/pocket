import Foundation
import CryptoKit
import AppKit
import SwiftUI

/// The single source of truth. Holds all items + clipboard history, persists them
/// encrypted, manages the vault lock, captures the clipboard, and owns settings.
@MainActor
final class Store: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var history: [ClipEntry] = []
    /// True once the user has passed Touch ID for this session.
    @Published var vaultUnlocked = false

    // MARK: Settings (persisted in UserDefaults)

    @Published var autoLockMinutes: Int {
        didSet { defaults.set(autoLockMinutes, forKey: "autoLockMinutes") }
    }
    @Published var captureClipboard: Bool {
        didSet { defaults.set(captureClipboard, forKey: "captureClipboard") }
    }
    @Published var showBadge: Bool {
        didSet { defaults.set(showBadge, forKey: "showBadge") }
    }

    private let defaults = UserDefaults.standard
    private let key = Crypto.masterKey()
    private let fileURL: URL

    private var lastActivity = Date()
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var pollTimer: Timer?
    private var lockTimer: Timer?

    private let historyLimit = 50

    init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pocket", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        self.fileURL = support.appendingPathComponent("store.dat")

        // Settings defaults on first launch.
        if defaults.object(forKey: "autoLockMinutes") == nil { defaults.set(5, forKey: "autoLockMinutes") }
        if defaults.object(forKey: "captureClipboard") == nil { defaults.set(true, forKey: "captureClipboard") }
        if defaults.object(forKey: "showBadge") == nil { defaults.set(true, forKey: "showBadge") }
        self.autoLockMinutes = defaults.integer(forKey: "autoLockMinutes")
        self.captureClipboard = defaults.bool(forKey: "captureClipboard")
        self.showBadge = defaults.bool(forKey: "showBadge")

        load()
        startTimers()
    }

    // MARK: - Derived collections

    /// Pinned items first (in their manual order); the rest float by frecency
    /// (usage count, then most-recently used), falling back to insertion order.
    private func sorted(_ list: [Item]) -> [Item] {
        list.enumerated()
            .sorted { a, b in
                let x = a.element, y = b.element
                if x.pinned != y.pinned { return x.pinned }
                if x.pinned { return a.offset < b.offset }          // pinned: manual order
                if x.useCount != y.useCount { return x.useCount > y.useCount }
                let lx = x.lastUsedAt ?? .distantPast
                let ly = y.lastUsedAt ?? .distantPast
                if lx != ly { return lx > ly }
                return a.offset < b.offset
            }
            .map(\.element)
    }

    var openItems: [Item] { sorted(items.filter { !$0.locked }) }
    var vaultItems: [Item] { sorted(items.filter { $0.locked }) }

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

    func togglePin(_ item: Item) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].pinned.toggle()
        save()
    }

    /// Reorders items within a tab. `orderedIDs` is the new order of the visible
    /// (non-pinned aware) list for that tab; we splice it back into `items`.
    func move(ids orderedIDs: [UUID]) {
        let idToItem = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let reordered = orderedIDs.compactMap { idToItem[$0] }
        let untouched = items.filter { !orderedIDs.contains($0.id) }
        items = reordered + untouched
        save()
    }

    // MARK: - Clipboard

    /// Copies an item and records the change so it is not re-captured as history.
    func copy(_ item: Item) {
        Clipboard.copy(item)
        lastChangeCount = NSPasteboard.general.changeCount
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].useCount += 1
            items[idx].lastUsedAt = Date()
            save()
        }
        noteActivity()
    }

    func copyHistory(_ entry: ClipEntry) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(entry.text, forType: .string)
        lastChangeCount = pb.changeCount
        noteActivity()
    }

    /// Turns a captured clipboard entry into a saved item.
    func promote(_ entry: ClipEntry) {
        let title = String(entry.preview.prefix(40))
        add(Item(title: title.isEmpty ? "Pano" : title, kind: .text, body: entry.text))
        history.removeAll { $0.id == entry.id }
        save()
    }

    func deleteHistory(_ entry: ClipEntry) {
        history.removeAll { $0.id == entry.id }
        save()
    }

    func clearHistory() {
        history.removeAll()
        save()
    }

    // MARK: - Vault

    func unlockVault() async -> Bool {
        if vaultUnlocked { return true }
        let ok = await Biometrics.authenticate(reason: "Kasayı açmak için kimliğini doğrula")
        if ok { vaultUnlocked = true; noteActivity() }
        return ok
    }

    func lockVault() {
        vaultUnlocked = false
    }

    func noteActivity() {
        lastActivity = Date()
    }

    // MARK: - Timers

    private func startTimers() {
        // Poll the pasteboard for new copies (there is no change notification on macOS).
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.capturePasteboard() }
        }
        // Auto-lock the vault after inactivity.
        lockTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkAutoLock() }
        }
    }

    private func capturePasteboard() {
        guard captureClipboard else { return }
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        // Respect password managers: skip concealed / transient / auto-generated copies.
        let skip: Set<String> = ["org.nspasteboard.ConcealedType",
                                 "org.nspasteboard.TransientType",
                                 "org.nspasteboard.AutoGeneratedType"]
        if let types = pb.types, types.contains(where: { skip.contains($0.rawValue) }) { return }

        guard let text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // De-dupe against the most recent capture and any saved item.
        if history.first?.text == text { return }
        history.removeAll { $0.text == text }
        history.insert(ClipEntry(text: text), at: 0)
        if history.count > historyLimit { history.removeLast(history.count - historyLimit) }
        save()
    }

    private func checkAutoLock() {
        guard vaultUnlocked, autoLockMinutes > 0 else { return }
        if Date().timeIntervalSince(lastActivity) > Double(autoLockMinutes) * 60 {
            vaultUnlocked = false
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let blob = try? Data(contentsOf: fileURL) else { return }
        do {
            let plain = try Crypto.decrypt(blob, key: key)
            let data = try JSONDecoder().decode(StoreData.self, from: plain)
            items = data.items
            history = data.history
        } catch {
            NSLog("pocket: failed to load store: \(error)")
        }
    }

    private func save() {
        do {
            let plain = try JSONEncoder().encode(StoreData(items: items, history: history))
            let blob = try Crypto.encrypt(plain, key: key)
            try blob.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            NSLog("pocket: failed to save store: \(error)")
        }
    }
}
