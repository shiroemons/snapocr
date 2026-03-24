import Carbon.HIToolbox
import Foundation

// Global callback storage for Carbon API interop
nonisolated(unsafe) private var globalHotkeyCallback: (() -> Void)?

@Observable
@MainActor
final class HotkeyService {
    var onHotkeyPressed: (@MainActor @Sendable () -> Void)?

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    var keyCode: UInt32 = UInt32(kVK_ANSI_O)
    var modifiers: UInt32 = UInt32(controlKey) | UInt32(shiftKey)

    func register() {
        // 1. Set up global callback
        let callback = onHotkeyPressed
        globalHotkeyCallback = {
            Task { @MainActor in
                callback?()
            }
        }

        // 2. Install event handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ -> OSStatus in
                globalHotkeyCallback?()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        // 3. Register hotkey
        // "SOCR" as FourCharCode: 0x534F4352
        let hotkeyID = EventHotKeyID(
            signature: 0x534F_4352,
            id: 1
        )
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }

    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        globalHotkeyCallback = nil
    }

    deinit {
        // Note: deinit runs on arbitrary thread, but unregister needs MainActor.
        // The app should call unregister() explicitly before deallocation.
    }
}
