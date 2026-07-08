import Carbon.HIToolbox
import AppKit

/// A global (system-wide) hotkey using the Carbon RegisterEventHotKey API.
/// This does NOT require Accessibility permission, unlike event taps.
final class HotKey {
    private var ref: EventHotKeyRef?
    private let id: UInt32
    private let callback: () -> Void

    private static var registry: [UInt32: HotKey] = [:]
    private static var nextID: UInt32 = 1
    private static var handlerInstalled = false

    /// - Parameters:
    ///   - keyCode: a virtual key code, e.g. `UInt32(kVK_Space)`.
    ///   - modifiers: Carbon modifier mask, e.g. `UInt32(cmdKey | shiftKey)`.
    init(keyCode: UInt32, modifiers: UInt32, callback: @escaping () -> Void) {
        self.callback = callback
        self.id = HotKey.nextID
        HotKey.nextID += 1

        HotKey.installHandlerIfNeeded()
        HotKey.registry[id] = self

        let hotKeyID = EventHotKeyID(signature: OSType(0x504b4554 /* "PKET" */), id: id)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &ref)
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        HotKey.registry[id] = nil
    }

    private static func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, _ -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            if let hk = HotKey.registry[hkID.id] {
                DispatchQueue.main.async { hk.callback() }
            }
            return noErr
        }, 1, &spec, nil, nil)
    }
}
