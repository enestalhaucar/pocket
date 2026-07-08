import SwiftUI
import AppKit

struct RootView: View {
    @EnvironmentObject private var store: Store

    enum Tab: Hashable { case pocket, vault, history }
    enum Screen: Equatable {
        case list
        case edit(Item?)
    }

    @State private var tab: Tab = .pocket
    @State private var screen: Screen = .list
    @State private var search = ""
    @State private var copiedID: UUID?
    @State private var editingLocked = false
    @State private var editPrefill = ""
    @State private var listHeight: CGFloat = 0
    @State private var selection = 0
    @FocusState private var searchFocused: Bool

    private let maxListHeight: CGFloat = 320

    var body: some View {
        VStack(spacing: 0) {
            switch screen {
            case .list:
                listScreen
            case .edit(let item):
                EditItemView(item: item, startLocked: editingLocked, prefill: editPrefill) {
                    editPrefill = ""
                    screen = .list
                }
                .environmentObject(store)
                .frame(height: 460)
            }
        }
        .frame(width: 360)
        .onReceive(NotificationCenter.default.publisher(for: .pocketDidOpen)) { _ in
            store.noteActivity()
            selection = 0
            if screen == .list { searchFocused = true }
        }
    }

    // MARK: - List screen

    private var listScreen: some View {
        VStack(spacing: 0) {
            header
            Divider()
            tabPicker
            searchField
            Divider()
            content
            Divider()
            footer
        }
        .onExitCommand(perform: handleEscape)
        .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
        .onKeyPress(.downArrow) { moveSelection(1); return .handled }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.full.fill").foregroundStyle(.tint)
            Text("pocket").font(.headline)
            Spacer()
            Button(action: quickAddFromClipboard) {
                Image(systemName: "doc.on.clipboard")
            }
            .buttonStyle(.borderless)
            .help("Panodakini kaydet")

            Button {
                editingLocked = (tab == .vault)
                editPrefill = ""
                screen = .edit(nil)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("Yeni öğe ekle")

            SettingsLink {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Ayarlar")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var tabPicker: some View {
        Picker("", selection: $tab) {
            Text("Cep").tag(Tab.pocket)
            Label("Kasa", systemImage: store.vaultUnlocked ? "lock.open.fill" : "lock.fill").tag(Tab.vault)
            Text("Geçmiş").tag(Tab.history)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onChange(of: tab) { _, newValue in
            selection = 0
            if newValue == .vault && !store.vaultUnlocked {
                Task { await store.unlockVault() }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Ara", text: $search)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit(activateSelection)
                .onChange(of: search) { _, _ in selection = 0 }
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        if tab == .vault && !store.vaultUnlocked {
            vaultLockedState
        } else if tab == .history {
            historyList
        } else if visibleItems.isEmpty {
            emptyState
        } else {
            itemList
        }
    }

    private var itemList: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    itemRow(index: index, item: item)
                }
            }
            .padding(6)
            .background(GeometryReader { g in
                Color.clear.preference(key: ContentHeightKey.self, value: g.size.height)
            })
        }
        .frame(height: min(max(listHeight, 1), maxListHeight))
        .onPreferenceChange(ContentHeightKey.self) { listHeight = $0 }
    }

    private func itemRow(index: Int, item: Item) -> some View {
        ItemRowView(
            item: item,
            selected: index == selection,
            copied: copiedID == item.id,
            onCopy: { copy(item) },
            onEdit: {
                editingLocked = item.locked
                editPrefill = ""
                screen = .edit(item)
            },
            onTogglePin: { store.togglePin(item) },
            onToggleLock: { store.toggleLock(item) },
            onDelete: { store.delete(item) }
        )
        .draggable(item.id.uuidString)
        .dropDestination(for: String.self) { dropped, _ in
            reorder(dropped.first, before: item)
            return true
        }
    }

    private var historyList: some View {
        Group {
            if store.history.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(store.history.enumerated()), id: \.element.id) { index, entry in
                            HistoryRowView(
                                entry: entry,
                                selected: index == selection,
                                copied: copiedID == entry.id,
                                onCopy: { copyHistory(entry) },
                                onSave: { store.promote(entry) },
                                onDelete: { store.deleteHistory(entry) }
                            )
                        }
                    }
                    .padding(6)
                    .background(GeometryReader { g in
                        Color.clear.preference(key: ContentHeightKey.self, value: g.size.height)
                    })
                }
                .frame(height: min(max(listHeight, 1), maxListHeight))
                .onPreferenceChange(ContentHeightKey.self) { listHeight = $0 }
            }
        }
    }

    private var vaultLockedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill").font(.system(size: 28)).foregroundStyle(.secondary)
            Text("Kasa kilitli").font(.headline)
            Text("Açmak için \(Biometrics.label) gerekiyor.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Kilidi aç") { Task { await store.unlockVault() } }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 44)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: emptyIcon).font(.system(size: 26)).foregroundStyle(.secondary)
            Text(emptyText).font(.callout).foregroundStyle(.secondary)
            if search.isEmpty && tab != .history {
                Button("Ekle") {
                    editingLocked = (tab == .vault)
                    editPrefill = ""
                    screen = .edit(nil)
                }
                .buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 44)
    }

    private var footer: some View {
        HStack {
            if tab == .history && !store.history.isEmpty {
                Button {
                    store.clearHistory()
                } label: {
                    Label("Geçmişi temizle", systemImage: "trash").font(.caption)
                }
                .buttonStyle(.borderless)
            } else if store.vaultUnlocked {
                Button {
                    store.lockVault()
                    if tab == .vault { tab = .pocket }
                } label: {
                    Label("Kilitle", systemImage: "lock.fill").font(.caption)
                }
                .buttonStyle(.borderless)
            }
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: {
                Text("Çıkış").font(.caption).foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Derived

    private var visibleItems: [Item] {
        let base = tab == .pocket ? store.openItems : store.vaultItems
        guard !search.isEmpty else { return base }
        let q = search.lowercased()
        return base.filter { $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q) }
    }

    private var emptyIcon: String {
        switch tab {
        case .history: return "clock"
        case .vault: return "lock.open"
        case .pocket: return "tray"
        }
    }

    private var emptyText: String {
        if !search.isEmpty { return "Sonuç bulunamadı" }
        switch tab {
        case .history: return "Pano geçmişi boş"
        default: return "Henüz bir şey yok"
        }
    }

    // MARK: - Actions

    private func copy(_ item: Item) {
        store.copy(item)
        flashCopied(item.id)
    }

    private func copyHistory(_ entry: ClipEntry) {
        store.copyHistory(entry)
        flashCopied(entry.id)
    }

    private func flashCopied(_ id: UUID) {
        copiedID = id
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if copiedID == id { copiedID = nil }
        }
    }

    private func quickAddFromClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        editingLocked = (tab == .vault)
        editPrefill = text
        screen = .edit(nil)
    }

    private func moveSelection(_ delta: Int) {
        let count = tab == .history ? store.history.count : visibleItems.count
        guard count > 0 else { return }
        selection = min(max(selection + delta, 0), count - 1)
        searchFocused = true
    }

    private func activateSelection() {
        if tab == .history {
            guard store.history.indices.contains(selection) else { return }
            copyHistory(store.history[selection])
        } else {
            guard visibleItems.indices.contains(selection) else { return }
            copy(visibleItems[selection])
        }
        NotificationCenter.default.post(name: .pocketClose, object: nil)
    }

    private func handleEscape() {
        if !search.isEmpty {
            search = ""
        } else {
            NotificationCenter.default.post(name: .pocketClose, object: nil)
        }
    }

    private func reorder(_ draggedID: String?, before target: Item) {
        guard let draggedID, let dragged = UUID(uuidString: draggedID), dragged != target.id else { return }
        var ids = visibleItems.map(\.id)
        ids.removeAll { $0 == dragged }
        guard let targetIdx = ids.firstIndex(of: target.id) else { return }
        ids.insert(dragged, at: targetIdx)
        store.move(ids: ids)
    }
}

/// Reports the natural height of the item list so the panel can size to it.
private struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
