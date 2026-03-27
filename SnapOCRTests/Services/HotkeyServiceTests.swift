@testable import SnapOCR
import Testing

@Suite("HotkeyService Tests")
@MainActor
struct HotkeyServiceTests {
    @Test func initialStateHasDefaultKeyCodeAndModifiers() {
        let service = HotkeyService()
        #expect(service.keyCode == SettingsService.defaultHotkeyKeyCode)
        #expect(service.modifiers == SettingsService.defaultHotkeyModifiers)
    }

    @Test func onHotkeyPressedIsNilByDefault() {
        let service = HotkeyService()
        #expect(service.onHotkeyPressed == nil)
    }

    @Test func updateHotkeyChangesKeyCodeAndModifiers() {
        let service = HotkeyService()
        let newKeyCode: UInt32 = 0x01  // kVK_ANSI_S
        let newModifiers: UInt32 = 0x0100  // cmdKey
        service.updateHotkey(keyCode: newKeyCode, modifiers: newModifiers)
        #expect(service.keyCode == newKeyCode)
        #expect(service.modifiers == newModifiers)
        service.unregister()
    }

    @Test func registerAndUnregisterDoNotCrash() {
        let service = HotkeyService()
        service.register()
        service.unregister()
    }

    @Test func doubleUnregisterDoesNotCrash() {
        let service = HotkeyService()
        service.register()
        service.unregister()
        service.unregister()
    }

    @Test func registerCalledMultipleTimesDoesNotCrash() {
        let service = HotkeyService()
        service.register()
        service.register()
        service.unregister()
    }

    @Test func registerUnregisterRegisterCycleDoesNotCrash() {
        let service = HotkeyService()
        service.register()
        service.unregister()
        service.register()
        service.unregister()
    }
}
