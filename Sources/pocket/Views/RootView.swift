import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store

    enum Tab { case pocket, vault }
    enum Screen: Equatable {
        case list
        case edit(Item?)   // nil == new item
    }

    @State private var tab: Tab = .pocket
    @State private var screen: Screen = .list
    @State private var search = ""
    @State private var copiedID: UUID?
    @State private var editingLocked = false

    var body: some View {
        VStack(spacing: 0) {
            switch screen {
            case .list:
                listScreen
            case .edit(let item):
                EditItemView(
                    item: item,
                    startLocked: editingLocked,
                    onDone: { screen = .list }
                )
                .environmentObject(store)
            }
        }
        .frame(width: 340)
        .frame(minHeight: 120)
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
                .frame(maxHeight: 360)

            Divider()
            footer
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "tray.full.fill")
                .foregroundStyle(.tint)
            Text("pocket")
                .font(.headline)
            Spacer()
            Button {
                editingLocked = (tab == .vault)
                screen = .edit(nil)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("Yeni öğe ekle")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var tabPicker: some View {
        Picker("", selection: $tab) {
            Text("Cep").tag(Tab.pocket)
            Label("Kasa", systemImage: store.vaultUnlocked ? "lock.open.fill" : "lock.fill")
                .tag(Tab.vault)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onChange(of: tab) { _, newValue in
            if newValue == .vault && !store.vaultUnlocked {
                Task { await store.unlockVault() }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Ara", text: $search)
                .textFieldStyle(.plain)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var content: some View {
        if tab == .vault && !store.vaultUnlocked {
            vaultLockedState
        } else if visibleItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(visibleItems) { item in
                        ItemRowView(
                            item: item,
                            copied: copiedID == item.id,
                            onCopy: { copy(item) },
                            onEdit: {
                                editingLocked = item.locked
                                screen = .edit(item)
                            },
                            onToggleLock: { store.toggleLock(item) },
                            onDelete: { store.delete(item) }
                        )
                    }
                }
                .padding(6)
            }
        }
    }

    private var vaultLockedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Kasa kilitli")
                .font(.headline)
            Text("Açmak için \(Biometrics.label) gerekiyor.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Kilidi aç") {
                Task { await store.unlockVault() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: tab == .vault ? "lock.open" : "tray")
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
            Text(search.isEmpty ? "Henüz bir şey yok" : "Sonuç bulunamadı")
                .font(.callout)
                .foregroundStyle(.secondary)
            if search.isEmpty {
                Button("Ekle") {
                    editingLocked = (tab == .vault)
                    screen = .edit(nil)
                }
                .buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private var footer: some View {
        HStack {
            if store.vaultUnlocked {
                Button {
                    store.lockVault()
                    if tab == .vault { tab = .pocket }
                } label: {
                    Label("Kilitle", systemImage: "lock.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Çıkış")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var visibleItems: [Item] {
        let base = tab == .pocket ? store.openItems : store.vaultItems
        guard !search.isEmpty else { return base }
        let q = search.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q)
        }
    }

    private func copy(_ item: Item) {
        Clipboard.copy(item)
        copiedID = item.id
        Task {
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            if copiedID == item.id { copiedID = nil }
        }
    }
}
