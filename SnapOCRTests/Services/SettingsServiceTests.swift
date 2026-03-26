import Carbon.HIToolbox
import Testing
@testable import SnapOCR

@Suite("SettingsService Tests")
@MainActor
struct SettingsServiceTests {
    private func makeService(
        preseeding: (UserDefaults) -> Void = { _ in }
    ) -> SettingsService {
        let suiteName = "com.shiroemons.snapocr.tests.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create test UserDefaults")
            return SettingsService()
        }
        preseeding(testDefaults)
        return SettingsService(userDefaults: testDefaults)
    }

    // MARK: - Default Values

    @Test func defaultHotkeyKeyCode() {
        let service = makeService()
        #expect(service.hotkeyKeyCode == UInt32(kVK_ANSI_O))
    }

    @Test func defaultHotkeyModifiers() {
        let service = makeService()
        let expected = UInt32(controlKey) | UInt32(shiftKey)
        #expect(service.hotkeyModifiers == expected)
    }

    @Test func defaultOCRLanguages() {
        let service = makeService()
        #expect(service.ocrLanguages == ["ja", "en"])
    }

    @Test func defaultHasCompletedOnboarding() {
        let service = makeService()
        #expect(service.hasCompletedOnboarding == false)
    }

    @Test func defaultShouldShowOnboarding() {
        let service = makeService()
        #expect(service.shouldShowOnboarding == true)
    }

    // MARK: - ocrLanguages Read/Write

    @Test func setOCRLanguagesToSingleLanguage() {
        let service = makeService()
        service.ocrLanguages = ["en"]
        #expect(service.ocrLanguages == ["en"])
    }

    @Test func setOCRLanguagesToMultipleLanguages() {
        let service = makeService()
        service.ocrLanguages = ["ja", "en", "zh-Hans"]
        #expect(service.ocrLanguages == ["ja", "en", "zh-Hans"])
    }

    @Test func setOCRLanguagesToEmptyArrayResetsToDefault() {
        let service = makeService()
        service.ocrLanguages = []
        #expect(service.ocrLanguages == ["ja", "en"])
    }

    @Test func overwriteOCRLanguages() {
        let service = makeService()
        service.ocrLanguages = ["en"]
        service.ocrLanguages = ["ja", "en"]
        #expect(service.ocrLanguages == ["ja", "en"])
    }

    // MARK: - hasCompletedOnboarding Toggle

    @Test func setHasCompletedOnboardingToTrue() {
        let service = makeService()
        service.hasCompletedOnboarding = true
        #expect(service.hasCompletedOnboarding == true)
    }

    @Test func shouldShowOnboardingIsFalseWhenOnboardingCompleted() {
        let service = makeService()
        service.hasCompletedOnboarding = true
        #expect(service.shouldShowOnboarding == false)
    }

    @Test func toggleHasCompletedOnboarding() {
        let service = makeService()
        service.hasCompletedOnboarding = true
        service.hasCompletedOnboarding = false
        #expect(service.hasCompletedOnboarding == false)
        #expect(service.shouldShowOnboarding == true)
    }

    // MARK: - hotkeyKeyCode / hotkeyModifiers Read/Write

    @Test func setHotkeyKeyCode() {
        let service = makeService()
        service.hotkeyKeyCode = UInt32(kVK_ANSI_S)
        #expect(service.hotkeyKeyCode == UInt32(kVK_ANSI_S))
    }

    @Test func setHotkeyModifiers() {
        let service = makeService()
        let newModifiers = UInt32(cmdKey)
        service.hotkeyModifiers = newModifiers
        #expect(service.hotkeyModifiers == newModifiers)
    }

    // MARK: - Notification Settings Defaults

    @Test func notificationCenterEnabledDefault() {
        let service = makeService()
        #expect(service.isNotificationCenterEnabled == true)
    }

    @Test func completionSoundEnabledDefault() {
        let service = makeService()
        #expect(service.isCompletionSoundEnabled == true)
    }

    @Test func toastEnabledDefault() {
        let service = makeService()
        #expect(service.isToastEnabled == false)
    }

    @Test func completionSoundNameDefault() {
        let service = makeService()
        #expect(service.completionSoundName == "Tink")
    }

    // MARK: - History Settings Defaults

    @Test func historyEnabledDefault() {
        let service = makeService()
        #expect(service.isHistoryEnabled == true)
    }

    @Test func maxHistoryCountDefault() {
        let service = makeService()
        #expect(service.maxHistoryCount == 100)
    }

    // MARK: - Notification Settings Read/Write

    @Test func setNotificationSettings() {
        let service = makeService()
        service.isNotificationCenterEnabled = false
        service.isToastEnabled = true
        service.completionSoundName = "Glass"
        #expect(service.isNotificationCenterEnabled == false)
        #expect(service.isToastEnabled == true)
        #expect(service.completionSoundName == "Glass")
    }

    // MARK: - History Settings Read/Write

    @Test func setHistorySettings() {
        let service = makeService()
        service.isHistoryEnabled = false
        service.maxHistoryCount = 200
        #expect(service.isHistoryEnabled == false)
        #expect(service.maxHistoryCount == 200)
    }

    // MARK: - maxHistoryCount Clamping

    @Test(arguments: [(0, 1), (-5, 1), (99999, 10000), (50, 50)])
    func maxHistoryCountClamping(input: Int, expected: Int) {
        let service = makeService()
        service.maxHistoryCount = input
        #expect(service.maxHistoryCount == expected)
    }

    // MARK: - hotkeyKeyCode Initialization Validation

    @Test(arguments: [0x10000, -1])
    func hotkeyKeyCodeFallsBackToDefaultWhenInvalid(storedValue: Int) {
        let service = makeService { $0.set(storedValue, forKey: "hotkeyKeyCode") }
        #expect(service.hotkeyKeyCode == SettingsService.defaultHotkeyKeyCode)
    }

    @Test func hotkeyKeyCodePersistence() {
        let service = makeService()

        service.hotkeyKeyCode = 0
        #expect(service.hotkeyKeyCode == 0)

        service.hotkeyKeyCode = 127
        #expect(service.hotkeyKeyCode == 127)
    }

    // MARK: - Notification Settings Individual Write

    @Test func setToastEnabled() {
        let service = makeService()

        service.isToastEnabled = true
        #expect(service.isToastEnabled == true)

        service.isToastEnabled = false
        #expect(service.isToastEnabled == false)
    }
}
