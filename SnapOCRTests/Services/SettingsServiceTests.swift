import Carbon.HIToolbox
import Testing
@testable import SnapOCR

@Suite("SettingsService Tests")
@MainActor
struct SettingsServiceTests {
    private func makeService() -> SettingsService {
        let suiteName = "com.shiroemons.snapocr.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        return SettingsService(userDefaults: testDefaults)
    }

    // MARK: - Default Values

    @Test @MainActor func defaultHotkeyKeyCode() {
        let service = makeService()
        #expect(service.hotkeyKeyCode == UInt32(kVK_ANSI_O))
    }

    @Test @MainActor func defaultHotkeyModifiers() {
        let service = makeService()
        let expected = UInt32(controlKey) | UInt32(shiftKey)
        #expect(service.hotkeyModifiers == expected)
    }

    @Test @MainActor func defaultOCRLanguages() {
        let service = makeService()
        #expect(service.ocrLanguages == ["ja", "en"])
    }

    @Test @MainActor func defaultHasCompletedOnboarding() {
        let service = makeService()
        #expect(service.hasCompletedOnboarding == false)
    }

    @Test @MainActor func defaultShouldShowOnboarding() {
        let service = makeService()
        #expect(service.shouldShowOnboarding == true)
    }

    // MARK: - ocrLanguages Read/Write

    @Test @MainActor func setOCRLanguagesToSingleLanguage() {
        let service = makeService()
        service.ocrLanguages = ["en"]
        #expect(service.ocrLanguages == ["en"])
    }

    @Test @MainActor func setOCRLanguagesToMultipleLanguages() {
        let service = makeService()
        service.ocrLanguages = ["ja", "en", "zh-Hans"]
        #expect(service.ocrLanguages == ["ja", "en", "zh-Hans"])
    }

    @Test @MainActor func setOCRLanguagesToEmptyArray() {
        let service = makeService()
        service.ocrLanguages = []
        #expect(service.ocrLanguages == [])
    }

    @Test @MainActor func overwriteOCRLanguages() {
        let service = makeService()
        service.ocrLanguages = ["en"]
        service.ocrLanguages = ["ja", "en"]
        #expect(service.ocrLanguages == ["ja", "en"])
    }

    // MARK: - hasCompletedOnboarding Toggle

    @Test @MainActor func setHasCompletedOnboardingToTrue() {
        let service = makeService()
        service.hasCompletedOnboarding = true
        #expect(service.hasCompletedOnboarding == true)
    }

    @Test @MainActor func shouldShowOnboardingIsFalseWhenOnboardingCompleted() {
        let service = makeService()
        service.hasCompletedOnboarding = true
        #expect(service.shouldShowOnboarding == false)
    }

    @Test @MainActor func toggleHasCompletedOnboarding() {
        let service = makeService()
        service.hasCompletedOnboarding = true
        service.hasCompletedOnboarding = false
        #expect(service.hasCompletedOnboarding == false)
        #expect(service.shouldShowOnboarding == true)
    }

    // MARK: - hotkeyKeyCode / hotkeyModifiers Read/Write

    @Test @MainActor func setHotkeyKeyCode() {
        let service = makeService()
        service.hotkeyKeyCode = UInt32(kVK_ANSI_S)
        #expect(service.hotkeyKeyCode == UInt32(kVK_ANSI_S))
    }

    @Test @MainActor func setHotkeyModifiers() {
        let service = makeService()
        let newModifiers = UInt32(cmdKey)
        service.hotkeyModifiers = newModifiers
        #expect(service.hotkeyModifiers == newModifiers)
    }
}
