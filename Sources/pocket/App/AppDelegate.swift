import AppKit
import SwiftUI
import Combine
import Carbon.HIToolbox

extension Notification.Name {
    static let pocketClose = Notification.Name("pocketClose")
    static let pocketDidOpen = Notification.Name("pocketDidOpen")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = Store()

    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var hotKey: HotKey?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Status bar item.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tray.full.fill", accessibilityDescription: "pocket")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Popover hosts the SwiftUI UI and sizes itself to the content.
        let host = NSHostingController(rootView: RootView().environmentObject(store))
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
        popover.behavior = .transient

        // Global hotkey (configurable): toggles the panel from anywhere.
        registerHotKey()
        NotificationCenter.default.addObserver(self, selector: #selector(registerHotKey),
                                               name: .pocketShortcutChanged, object: nil)

        // Lock the vault when the Mac sleeps or the screen locks.
        let wc = NSWorkspace.shared.notificationCenter
        wc.addObserver(self, selector: #selector(lockNow), name: NSWorkspace.willSleepNotification, object: nil)
        wc.addObserver(self, selector: #selector(lockNow), name: NSWorkspace.screensDidSleepNotification, object: nil)

        // Close the panel when the UI asks (Esc key).
        NotificationCenter.default.addObserver(self, selector: #selector(closePopover),
                                               name: .pocketClose, object: nil)

        // Menu bar badge: reflect the number of open (non-vault) items.
        Publishers.CombineLatest(store.$items, store.$showBadge)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in self?.updateBadge() }
            .store(in: &cancellables)
        updateBadge()
    }

    private func updateBadge() {
        guard let button = statusItem.button else { return }
        let count = store.items.filter { !$0.locked }.count
        button.title = (store.showBadge && count > 0) ? " \(count)" : ""
    }

    @objc private func registerHotKey() {
        let s = Shortcut.load()
        hotKey = HotKey(keyCode: s.keyCode, modifiers: s.carbonModifiers) { [weak self] in
            self?.togglePopover()
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NotificationCenter.default.post(name: .pocketDidOpen, object: nil)
        }
    }

    @objc private func closePopover() {
        if popover.isShown { popover.performClose(nil) }
    }

    @objc private func lockNow() {
        store.lockVault()
    }
}
