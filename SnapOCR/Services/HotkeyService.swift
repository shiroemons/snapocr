import Carbon.HIToolbox
import Foundation
import os
import Synchronization

// Global callback storage for Carbon API interop
private let globalHotkeyCallbackStorage = Mutex<(@Sendable () -> Void)?>(nil)

@MainActor
final class HotkeyService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "HotkeyService")

    var onHotkeyPressed: (@MainActor @Sendable () -> Void)?

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    var keyCode: UInt32 = SettingsService.defaultHotkeyKeyCode
    var modifiers: UInt32 = SettingsService.defaultHotkeyModifiers

    func register() {
        unregister()

        // 1. Set up global callback
        globalHotkeyCallbackStorage.withLock { $0 = { [weak self] in
            MainActor.assumeIsolated {
                self?.onHotkeyPressed?()
            }
        }}

        // 2. Install event handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ -> OSStatus in
                globalHotkeyCallbackStorage.withLock { $0?() }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
        if handlerStatus != noErr {
            Self.logger.error("InstallEventHandler failed with status: \(handlerStatus)")
        }

        // 3. Register hotkey ("SOCR" in ASCII — unique app signature)
        let hotkeyID = EventHotKeyID(
            signature: 0x534F_4352,
            id: 1
        )
        let hotkeyStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        if hotkeyStatus != noErr {
            Self.logger.error("RegisterEventHotKey failed with status: \(hotkeyStatus)")
            hotkeyRef = nil
        }
    }

    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        guard keyCode <= 127 else {
            Self.logger.warning("Ignoring invalid keyCode \(keyCode) — must be in range 0...127")
            return
        }
        self.keyCode = keyCode
        self.modifiers = modifiers
        register()
    }

    /// Unregisters the hotkey and removes the event handler.
    /// Must be called explicitly before deallocation (deinit cannot run on MainActor).
    func unregister() {
        if let ref = hotkeyRef {
            let status = UnregisterEventHotKey(ref)
            if status != noErr {
                Self.logger.warning("UnregisterEventHotKey failed with status: \(status)")
            }
            hotkeyRef = nil
        }
        if let ref = eventHandlerRef {
            let status = RemoveEventHandler(ref)
            if status != noErr {
                Self.logger.warning("RemoveEventHandler failed with status: \(status)")
            }
            eventHandlerRef = nil
        }
        globalHotkeyCallbackStorage.withLock { $0 = nil }
    }
}
