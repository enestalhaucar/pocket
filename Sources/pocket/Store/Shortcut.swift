import AppKit
import Carbon.HIToolbox

extension Notification.Name {
    static let pocketShortcutChanged = Notification.Name("pocketShortcutChanged")
}

/// The global hotkey configuration, persisted in UserDefaults.
struct Shortcut: Equatable {
    var keyCode: UInt32
    /// Carbon modifier mask (cmdKey | shiftKey | optionKey | controlKey).
    var carbonModifiers: UInt32

    static let `default` = Shortcut(keyCode: UInt32(kVK_Space),
                                    carbonModifiers: UInt32(cmdKey | shiftKey))

    // MARK: Persistence

    static func load() -> Shortcut {
        let d = UserDefaults.standard
        guard d.object(forKey: "hotkeyKeyCode") != nil else { return .default }
        return Shortcut(keyCode: UInt32(d.integer(forKey: "hotkeyKeyCode")),
                        carbonModifiers: UInt32(d.integer(forKey: "hotkeyModifiers")))
    }

    func save() {
        let d = UserDefaults.standard
        d.set(Int(keyCode), forKey: "hotkeyKeyCode")
        d.set(Int(carbonModifiers), forKey: "hotkeyModifiers")
        NotificationCenter.default.post(name: .pocketShortcutChanged, object: nil)
    }

    /// Build from an NSEvent captured by the recorder.
    static func from(event: NSEvent) -> Shortcut? {
        let flags = event.modifierFlags
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        // Require at least one modifier so we don't hijack plain keys.
        guard carbon != 0 else { return nil }
        return Shortcut(keyCode: UInt32(event.keyCode), carbonModifiers: carbon)
    }

    // MARK: Display

    var display: String {
        var s = ""
        if carbonModifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        s += Shortcut.keyName(keyCode)
        return s
    }

    static func keyName(_ code: UInt32) -> String {
        let map: [UInt32: String] = [
            UInt32(kVK_Space): "Space", UInt32(kVK_Return): "↩", UInt32(kVK_Tab): "⇥",
            UInt32(kVK_Escape): "⎋", UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B",
            UInt32(kVK_ANSI_C): "C", UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E",
            UInt32(kVK_ANSI_F): "F", UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H",
            UInt32(kVK_ANSI_I): "I", UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K",
            UInt32(kVK_ANSI_L): "L", UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N",
            UInt32(kVK_ANSI_O): "O", UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q",
            UInt32(kVK_ANSI_R): "R", UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T",
            UInt32(kVK_ANSI_U): "U", UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W",
            UInt32(kVK_ANSI_X): "X", UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
            UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
            UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
            UInt32(kVK_ANSI_9): "9"
        ]
        return map[code] ?? "?"
    }
}
