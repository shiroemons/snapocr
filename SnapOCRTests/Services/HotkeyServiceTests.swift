import Carbon.HIToolbox
@testable import SnapOCR
import Testing

/// 実際にシステムへ登録するので、通常使わない F18 と F19 だけを使い、テストの終わりに必ず解除する。
/// 同じキーを使うテスト同士が競合しないよう、途中で await せず MainActor 上で続けて実行されるようにしている。
@Suite("HotkeyService Tests")
@MainActor
struct HotkeyServiceTests {
    private let f18 = UInt32(kVK_F18)
    private let f19 = UInt32(kVK_F19)
    private let noModifiers: UInt32 = 0

    @Test func initialStateHasDefaultKeyCodeAndModifiers() {
        let service = HotkeyService()
        #expect(service.keyCode == SettingsService.defaultHotkeyKeyCode)
        #expect(service.modifiers == SettingsService.defaultHotkeyModifiers)
    }

    @Test func registeringValidKeyUpdatesKeyCodeAndModifiers() {
        let service = HotkeyService()
        defer { service.unregister() }

        #expect(service.updateHotkey(keyCode: f18, modifiers: noModifiers))

        #expect(service.keyCode == f18)
        #expect(service.modifiers == noModifiers)
    }

    @Test func registeringSameCombinationAgainSucceeds() {
        let service = HotkeyService()
        defer { service.unregister() }
        #expect(service.updateHotkey(keyCode: f18, modifiers: noModifiers))

        #expect(service.updateHotkey(keyCode: f18, modifiers: noModifiers))

        #expect(service.keyCode == f18)
    }

    @Test func changingToKeyHeldByAnotherInstanceFailsAndKeepsOldKey() {
        let holder = HotkeyService()
        let service = HotkeyService()
        let observer = HotkeyService()
        defer {
            holder.unregister()
            service.unregister()
            observer.unregister()
        }
        #expect(holder.updateHotkey(keyCode: f18, modifiers: noModifiers))
        #expect(service.updateHotkey(keyCode: f19, modifiers: noModifiers))

        #expect(service.updateHotkey(keyCode: f18, modifiers: noModifiers) == false)

        #expect(service.keyCode == f19)
        #expect(service.modifiers == noModifiers)
        // F19 が取れないことで、失敗した後も旧キーが登録されたままだと分かる
        #expect(observer.updateHotkey(keyCode: f19, modifiers: noModifiers) == false)
    }

    @Test func invalidKeyIsRejectedAndKeepsOldKey() {
        let service = HotkeyService()
        defer { service.unregister() }
        #expect(service.updateHotkey(keyCode: f18, modifiers: noModifiers))

        #expect(service.updateHotkey(keyCode: UInt32(kVK_ANSI_O), modifiers: noModifiers) == false)
        #expect(service.updateHotkey(keyCode: 128, modifiers: UInt32(controlKey)) == false)

        #expect(service.keyCode == f18)
        #expect(service.modifiers == noModifiers)
    }

    @Test func unregisterReleasesKeyForOtherInstances() {
        let service = HotkeyService()
        let other = HotkeyService()
        defer {
            service.unregister()
            other.unregister()
        }
        #expect(service.updateHotkey(keyCode: f18, modifiers: noModifiers))

        service.unregister()
        // 2 回目の解除で状態が壊れないことも、続く再登録で確かめる
        service.unregister()

        #expect(other.updateHotkey(keyCode: f18, modifiers: noModifiers))
        other.unregister()
        #expect(service.updateHotkey(keyCode: f18, modifiers: noModifiers))
    }

    @Test func unregisterKeepsKeyForRollback() {
        let service = HotkeyService()
        defer { service.unregister() }
        #expect(service.updateHotkey(keyCode: f18, modifiers: noModifiers))

        service.unregister()

        #expect(service.keyCode == f18)
        #expect(service.modifiers == noModifiers)
    }

    @Test func deinitReleasesKey() {
        let other = HotkeyService()
        defer { other.unregister() }
        var service: HotkeyService? = HotkeyService()
        #expect(service?.updateHotkey(keyCode: f19, modifiers: noModifiers) == true)

        service = nil

        #expect(other.updateHotkey(keyCode: f19, modifiers: noModifiers))
    }
}
