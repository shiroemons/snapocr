import Carbon.HIToolbox
import Foundation
@testable import SnapOCR
import Testing

private let shift = UInt32(shiftKey)
private let control = UInt32(controlKey)
private let option = UInt32(optionKey)
private let command = UInt32(cmdKey)

/// 2 つ目の `SettingsService` を同じ UserDefaults から作り、保存と復元を確かめる。
@Suite("SettingsService Persistence Tests")
@MainActor
struct SettingsServicePersistenceTests {
    private let defaults = TestUserDefaults()

    private func makeService() -> SettingsService {
        SettingsService(userDefaults: defaults)
    }

    // MARK: - Round Trip

    @Test func allSettingsAreRestored() {
        let original = makeService()
        original.appearanceMode = .dark
        original.appLanguage = .english
        original.hotkeyKeyCode = UInt32(kVK_ANSI_K)
        original.hotkeyModifiers = control | command
        original.ocrLanguages = ["en", "zh-Hans"]
        original.hasCompletedOnboarding = true
        original.isNotificationCenterEnabled = false
        original.isNotificationPreviewEnabled = true
        original.isCompletionSoundEnabled = false
        original.completionSoundName = "Glass"
        original.isToastEnabled = true
        original.isHistoryEnabled = false
        original.maxHistoryCount = 250

        let restored = makeService()

        #expect(restored.appearanceMode == .dark)
        #expect(restored.appLanguage == .english)
        #expect(restored.hotkeyKeyCode == UInt32(kVK_ANSI_K))
        #expect(restored.hotkeyModifiers == control | command)
        #expect(restored.ocrLanguages == ["en", "zh-Hans"])
        #expect(restored.hasCompletedOnboarding == true)
        #expect(restored.isNotificationCenterEnabled == false)
        #expect(restored.isNotificationPreviewEnabled == true)
        #expect(restored.isCompletionSoundEnabled == false)
        #expect(restored.completionSoundName == "Glass")
        #expect(restored.isToastEnabled == true)
        #expect(restored.isHistoryEnabled == false)
        #expect(restored.maxHistoryCount == 250)
    }

    @Test func recordingStateIsNotRestored() {
        makeService().isRecordingHotkey = true
        #expect(makeService().isRecordingHotkey == false)
    }

    @Test(arguments: [(0, 1), (99999, 10000)])
    func clampedMaxHistoryCountIsSaved(input: Int, expected: Int) {
        makeService().maxHistoryCount = input
        #expect(makeService().maxHistoryCount == expected)
    }

    @Test func languagesResetFromEmptyAreSaved() {
        let original = makeService()
        original.ocrLanguages = ["en"]
        original.ocrLanguages = []
        #expect(makeService().ocrLanguages == OCRLanguageDefinition.defaultLanguageCodes)
    }

    // MARK: - Restoring Valid Hotkeys

    @Test(arguments: [
        (UInt32(kVK_ANSI_K), control | command),
        (UInt32(kVK_ANSI_A), command | shift),
        (UInt32(kVK_F13), UInt32(0)),
    ])
    func validStoredHotkeyIsRestored(keyCode: UInt32, modifiers: UInt32) {
        defaults.set(Int(keyCode), forKey: "hotkeyKeyCode")
        defaults.set(Int(modifiers), forKey: "hotkeyModifiers")

        let service = makeService()

        #expect(service.hotkeyKeyCode == keyCode)
        #expect(service.hotkeyModifiers == modifiers)
    }

    // MARK: - Restoring Invalid Hotkeys

    @Test(arguments: [128, 0xFFFF, 0x10000, -1])
    func invalidStoredKeyCodeFallsBackToDefaultHotkey(keyCode: Int) {
        defaults.set(keyCode, forKey: "hotkeyKeyCode")
        defaults.set(Int(control | command), forKey: "hotkeyModifiers")

        expectDefaultHotkey(makeService())
    }

    @Test(arguments: [0, Int(shift), Int(option), Int(command), Int(option | shift), Int(control) | 0x1])
    func invalidStoredModifiersFallBackToDefaultHotkey(modifiers: Int) {
        defaults.set(kVK_ANSI_A, forKey: "hotkeyKeyCode")
        defaults.set(modifiers, forKey: "hotkeyModifiers")

        expectDefaultHotkey(makeService())
    }

    private func expectDefaultHotkey(
        _ service: SettingsService,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(service.hotkeyKeyCode == SettingsService.defaultHotkeyKeyCode, sourceLocation: sourceLocation)
        #expect(service.hotkeyModifiers == SettingsService.defaultHotkeyModifiers, sourceLocation: sourceLocation)
    }

    // MARK: - Restoring Languages

    @Test(arguments: [[], ["xx"], ["xx", "yy"]] as [[String]])
    func storedLanguagesWithoutKnownCodeFallBackToDefault(stored: [String]) {
        defaults.set(stored, forKey: "ocrLanguages")
        #expect(makeService().ocrLanguages == OCRLanguageDefinition.defaultLanguageCodes)
    }

    @Test func unknownStoredLanguageCodesAreRemoved() {
        defaults.set(["xx", "en", "zh-Hans", "yy"], forKey: "ocrLanguages")
        #expect(makeService().ocrLanguages == ["en", "zh-Hans"])
    }

    // MARK: - Restoring Other Settings

    @Test(arguments: [(0, 1), (99999, 10000)])
    func storedMaxHistoryCountOutOfRangeIsClamped(stored: Int, expected: Int) {
        defaults.set(stored, forKey: "maxHistoryCount")
        #expect(makeService().maxHistoryCount == expected)
    }

    @Test func storedAppearanceOutOfRangeFallsBackToSystem() {
        defaults.set("sepia", forKey: "appearanceMode")
        #expect(makeService().appearanceMode == .system)
    }

    @Test func storedLanguageOutOfRangeFallsBackToSystem() {
        defaults.set("fr", forKey: "appLanguage")
        #expect(makeService().appLanguage == .system)
    }
}
