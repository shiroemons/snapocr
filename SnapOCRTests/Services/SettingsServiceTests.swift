import Carbon.HIToolbox
import Foundation
@testable import SnapOCR
import Testing

@Suite("SettingsService Tests")
@MainActor
struct SettingsServiceTests {
    private let testDefaults = TestUserDefaults()

    private func makeService() -> SettingsService {
        SettingsService(userDefaults: testDefaults)
    }

    // MARK: - Default Values

    @Test func defaultHotkeyIsControlShiftO() {
        let service = makeService()
        #expect(service.hotkeyKeyCode == UInt32(kVK_ANSI_O))
        #expect(service.hotkeyModifiers == UInt32(controlKey) | UInt32(shiftKey))
        #expect(service.isRecordingHotkey == false)
    }

    @Test func defaultAppearanceAndLanguageFollowSystem() {
        let service = makeService()
        #expect(service.appearanceMode == .system)
        #expect(service.appLanguage == .system)
    }

    @Test func defaultOCRLanguages() {
        #expect(makeService().ocrLanguages == ["ja", "en"])
    }

    @Test func defaultNotificationSettings() {
        let service = makeService()
        #expect(service.isNotificationCenterEnabled == true)
        #expect(service.isNotificationPreviewEnabled == false)
        #expect(service.isCompletionSoundEnabled == true)
        #expect(service.completionSoundName == "Tink")
        #expect(service.isToastEnabled == false)
    }

    @Test func defaultHistorySettings() {
        let service = makeService()
        #expect(service.isHistoryEnabled == true)
        #expect(service.maxHistoryCount == 100)
    }

    // MARK: - Onboarding

    @Test func onboardingIsShownUntilCompleted() {
        let service = makeService()
        #expect(service.hasCompletedOnboarding == false)
        #expect(service.shouldShowOnboarding == true)

        service.hasCompletedOnboarding = true
        #expect(service.shouldShowOnboarding == false)

        service.hasCompletedOnboarding = false
        #expect(service.shouldShowOnboarding == true)
    }

    // MARK: - ocrLanguages

    @Test func emptyOCRLanguagesResetToDefault() {
        let service = makeService()
        service.ocrLanguages = ["en"]
        service.ocrLanguages = []
        #expect(service.ocrLanguages == ["ja", "en"])
    }

    // MARK: - maxHistoryCount Clamping

    @Test(arguments: [(0, 1), (-5, 1), (1, 1), (50, 50), (10000, 10000), (99999, 10000)])
    func maxHistoryCountIsClamped(input: Int, expected: Int) {
        let service = makeService()
        service.maxHistoryCount = input
        #expect(service.maxHistoryCount == expected)
    }

    // MARK: - hotkeyDisplayString

    @Test func hotkeyDisplayStringFollowsCurrentHotkey() {
        let service = makeService()
        #expect(service.hotkeyDisplayString == "⌃⇧O")

        service.hotkeyKeyCode = UInt32(kVK_ANSI_K)
        service.hotkeyModifiers = UInt32(controlKey) | UInt32(cmdKey)
        #expect(service.hotkeyDisplayString == "⌃⌘K")
    }
}
