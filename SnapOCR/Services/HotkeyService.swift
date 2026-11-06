import Carbon.HIToolbox
import Foundation
import os

@MainActor
final class HotkeyService: HotkeyServiceProtocol {
    private static let logger = Logger(category: "HotkeyService")
    /// "SOCR" in ASCII — unique app signature
    private static let hotkeyID = EventHotKeyID(signature: 0x534F_4352, id: 1)

    var onHotkeyPressed: (@MainActor () -> Void)?

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private(set) var keyCode: UInt32 = SettingsService.defaultHotkeyKeyCode
    private(set) var modifiers: UInt32 = SettingsService.defaultHotkeyModifiers

    isolated deinit {
        // ハンドラは self を非保持の userData として持つので、解放前に必ず外す
        unregister()
    }

    /// 指定のキーを登録する。失敗したときは旧キーを登録したまま false を返す。
    @discardableResult
    func updateHotkey(keyCode newKeyCode: UInt32, modifiers newModifiers: UInt32) -> Bool {
        guard KeyCodeMapping.isValidHotkey(keyCode: newKeyCode, modifiers: newModifiers) else {
            Self.logger.warning("Ignoring invalid hotkey: keyCode \(newKeyCode), modifiers \(newModifiers)")
            return false
        }
        // 同じ組み合わせを二重に登録すると eventHotKeyExistsErr になる
        if hotkeyRef != nil, newKeyCode == keyCode, newModifiers == modifiers {
            return true
        }
        guard installEventHandlerIfNeeded() else { return false }

        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            newKeyCode,
            newModifiers,
            Self.hotkeyID,
            GetApplicationEventTarget(),
            0,
            &newRef
        )
        guard status == noErr else {
            Self.logger.error("RegisterEventHotKey failed with status: \(status)")
            return false
        }

        // 新しいキーの登録に成功するまで旧キーを解除しない
        releaseHotkey()
        hotkeyRef = newRef
        keyCode = newKeyCode
        modifiers = newModifiers
        return true
    }

    /// Unregisters the hotkey and removes the event handler.
    func unregister() {
        releaseHotkey()
        if let ref = eventHandlerRef {
            let status = RemoveEventHandler(ref)
            if status != noErr {
                Self.logger.warning("RemoveEventHandler failed with status: \(status)")
            }
            eventHandlerRef = nil
        }
    }

    private func releaseHotkey() {
        guard let ref = hotkeyRef else { return }
        let status = UnregisterEventHotKey(ref)
        if status != noErr {
            Self.logger.warning("UnregisterEventHotKey failed with status: \(status)")
        }
        hotkeyRef = nil
    }

    private func installEventHandlerIfNeeded() -> Bool {
        guard eventHandlerRef == nil else { return true }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                // Carbon のイベントはメインスレッドで配信される
                MainActor.assumeIsolated {
                    service.onHotkeyPressed?()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        guard status == noErr else {
            Self.logger.error("InstallEventHandler failed with status: \(status)")
            return false
        }
        return true
    }
}
