import Foundation
import Testing
@testable import SnapOCR

@Suite("SnapOCR App Tests")
@MainActor
struct SnapOCRTests {

    private func makeSettingsService() -> SettingsService {
        let suiteName = "com.shiroemons.snapocr.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        return SettingsService(userDefaults: testDefaults)
    }

    @Test func appViewModelInitialState() {
        let viewModel = AppViewModel()
        #expect(viewModel.isCapturing == false)
        #expect(viewModel.lastError == nil)
    }

    @Test func setupRegistersHotkeyCallback() {
        let hotkeyService = HotkeyService()
        let viewModel = AppViewModel(
            hotkeyService: hotkeyService,
            settingsService: makeSettingsService()
        )
        #expect(hotkeyService.onHotkeyPressed == nil)
        viewModel.setup()
        #expect(hotkeyService.onHotkeyPressed != nil)
        viewModel.teardown()
    }

    @Test func teardownUnregistersHotkey() {
        let hotkeyService = HotkeyService()
        let viewModel = AppViewModel(
            hotkeyService: hotkeyService,
            settingsService: makeSettingsService()
        )
        viewModel.setup()
        viewModel.teardown()
        // teardown unregisters the Carbon hotkey but does not clear onHotkeyPressed
        #expect(hotkeyService.onHotkeyPressed != nil)
    }

    @Test func teardownFollowedBySetupDoesNotCrash() {
        let hotkeyService = HotkeyService()
        let viewModel = AppViewModel(
            hotkeyService: hotkeyService,
            settingsService: makeSettingsService()
        )
        viewModel.setup()
        viewModel.teardown()
        viewModel.setup()
        viewModel.teardown()
    }

    @Test func isCapturingIsFalseAfterSetup() {
        let viewModel = AppViewModel(settingsService: makeSettingsService())
        viewModel.setup()
        #expect(viewModel.isCapturing == false)
        viewModel.teardown()
    }

    @Test func teardownBeforeSetupDoesNotCrash() {
        let hotkeyService = HotkeyService()
        let viewModel = AppViewModel(
            hotkeyService: hotkeyService,
            settingsService: makeSettingsService()
        )
        viewModel.teardown()
        viewModel.setup()
        viewModel.teardown()
    }

    @Test func startCaptureSetsCapturePermissionError() async throws {
        let permissionService = PermissionService()
        permissionService.checkPermission()
        // This test only applies when Screen Recording permission is not granted
        guard !permissionService.isScreenCapturePermitted else { return }

        let viewModel = AppViewModel(
            permissionService: permissionService,
            settingsService: makeSettingsService()
        )
        viewModel.startCapture()
        // Poll until lastError is set or timeout (max 1s)
        for _ in 0..<100 {
            if viewModel.lastError != nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(viewModel.lastError != nil)
    }
}
