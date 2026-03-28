import CoreGraphics
import Foundation
import SwiftData
import Testing
@testable import SnapOCR

@Suite("AppViewModel Tests")
@MainActor
struct AppViewModelTests {
    // MARK: - Helpers

    struct ViewModelResult {
        let viewModel: AppViewModel
        let ocrService: MockOCRService
        let captureService: MockCaptureService
        let clipboardService: MockClipboardService
        let notificationService: MockNotificationService
        let regionSelector: MockRegionSelector
        let settingsService: SettingsService
    }

    func makeSettingsService() -> SettingsService {
        let suiteName = "com.shiroemons.snapocr.tests.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create test UserDefaults")
            return SettingsService()
        }
        return SettingsService(userDefaults: testDefaults)
    }

    func makeViewModel(
        ocrService: MockOCRService = MockOCRService(),
        captureService: MockCaptureService = MockCaptureService(),
        clipboardService: MockClipboardService = MockClipboardService(),
        notificationService: MockNotificationService = MockNotificationService(),
        regionSelector: MockRegionSelector = MockRegionSelector(),
        settingsService: SettingsService? = nil,
        historyService: HistoryService? = nil
    ) -> ViewModelResult {
        let settings = settingsService ?? makeSettingsService()
        let vm = AppViewModel(
            settingsService: settings,
            historyService: historyService,
            ocrService: ocrService,
            captureService: captureService,
            clipboardService: clipboardService,
            notificationService: notificationService,
            regionSelector: regionSelector
        )
        return ViewModelResult(
            viewModel: vm,
            ocrService: ocrService,
            captureService: captureService,
            clipboardService: clipboardService,
            notificationService: notificationService,
            regionSelector: regionSelector,
            settingsService: settings
        )
    }

    func waitForCaptureCompletion(_ vm: AppViewModel) async throws {
        for _ in 0..<100 {
            if !vm.isCapturing { return }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    func validSelectionResult() -> SelectionResult {
        SelectionResult(
            rect: CGRect(x: 0, y: 0, width: 100, height: 100),
            displayID: 1,
            screenSize: CGSize(width: 1920, height: 1080),
            scaleFactor: 2.0
        )
    }

    func isPermissionGranted() -> Bool {
        let permissionService = PermissionService()
        permissionService.checkPermission()
        return permissionService.isScreenCapturePermitted
    }

    // MARK: - Initial State

    @Test func appViewModelInitialState() {
        let viewModel = AppViewModel()
        #expect(viewModel.isCapturing == false)
        #expect(viewModel.lastError == nil)
    }

    // MARK: - Setup / Teardown

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

    // MARK: - handleRecognizedText Flow

    @Test func captureSuccess_copiesTextToClipboard() async throws {
        guard isPermissionGranted() else { return }

        let ocr = MockOCRService()
        ocr.recognizeTextResult = "Hello"
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let result = makeViewModel(
            ocrService: ocr,
            regionSelector: regionSelector
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.clipboardService.copyCallCount == 1)
        #expect(result.clipboardService.lastCopiedText == "Hello")
    }

    @Test func captureSuccess_sendsNotification() async throws {
        guard isPermissionGranted() else { return }

        let ocr = MockOCRService()
        ocr.recognizeTextResult = "Hello"
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let result = makeViewModel(
            ocrService: ocr,
            regionSelector: regionSelector
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.notificationService.notifySuccessCallCount == 1)
    }

    @Test func captureSuccess_addsHistoryRecord_whenEnabled() async throws {
        guard isPermissionGranted() else { return }

        let ocr = MockOCRService()
        ocr.recognizeTextResult = "Hello"
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let settings = makeSettingsService()
        settings.isHistoryEnabled = true

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CaptureRecord.self, configurations: config)
        let historyService = HistoryService(modelContainer: container)

        let result = makeViewModel(
            ocrService: ocr,
            regionSelector: regionSelector,
            settingsService: settings,
            historyService: historyService
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(!historyService.recentRecords.isEmpty)
    }

    @Test func captureSuccess_skipsHistory_whenDisabled() async throws {
        guard isPermissionGranted() else { return }

        let ocr = MockOCRService()
        ocr.recognizeTextResult = "Hello"
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let settings = makeSettingsService()
        settings.isHistoryEnabled = false

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CaptureRecord.self, configurations: config)
        let historyService = HistoryService(modelContainer: container)

        let result = makeViewModel(
            ocrService: ocr,
            regionSelector: regionSelector,
            settingsService: settings,
            historyService: historyService
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(historyService.recentRecords.isEmpty)
    }

    @Test func captureSuccess_skipsHistory_whenHistoryServiceNil() async throws {
        guard isPermissionGranted() else { return }

        let ocr = MockOCRService()
        ocr.recognizeTextResult = "Hello"
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let result = makeViewModel(
            ocrService: ocr,
            regionSelector: regionSelector,
            historyService: nil
        )

        // Must not crash when historyService is nil
        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)
    }

    @Test func captureSuccess_doesNotNotify_whenCopyFails() async throws {
        guard isPermissionGranted() else { return }

        let ocr = MockOCRService()
        ocr.recognizeTextResult = "Hello"
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()
        let clipboard = MockClipboardService()
        clipboard.copyResult = false

        let result = makeViewModel(
            ocrService: ocr,
            captureService: MockCaptureService(),
            clipboardService: clipboard,
            regionSelector: regionSelector
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.notificationService.notifySuccessCallCount == 0)
    }

    // MARK: - performCapture Error Paths

    @Test func captureError_emptyOCRResult_setsLastError() async throws {
        guard isPermissionGranted() else { return }

        let ocr = MockOCRService()
        ocr.recognizeTextResult = ""
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let result = makeViewModel(
            ocrService: ocr,
            regionSelector: regionSelector
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.viewModel.lastError != nil)
    }

    @Test func captureError_invalidRegion_setsLastError() async throws {
        guard isPermissionGranted() else { return }

        let capture = MockCaptureService()
        capture.captureRegionError = CaptureError.invalidRegion
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let result = makeViewModel(
            captureService: capture,
            regionSelector: regionSelector
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.viewModel.lastError != nil)
    }

    @Test func captureError_noDisplay_setsLastError() async throws {
        guard isPermissionGranted() else { return }

        let capture = MockCaptureService()
        capture.captureRegionError = CaptureError.noDisplay
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let result = makeViewModel(
            captureService: capture,
            regionSelector: regionSelector
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.viewModel.lastError != nil)
    }

    @Test func captureError_captureFailure_setsLastError() async throws {
        guard isPermissionGranted() else { return }

        let capture = MockCaptureService()
        capture.captureRegionError = CaptureError.captureFailure
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let result = makeViewModel(
            captureService: capture,
            regionSelector: regionSelector
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.viewModel.lastError != nil)
    }

    @Test func captureError_ocrThrows_setsLastError() async throws {
        guard isPermissionGranted() else { return }

        let ocr = MockOCRService()
        ocr.recognizeTextError = NSError(domain: "test", code: 1)
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = validSelectionResult()

        let result = makeViewModel(
            ocrService: ocr,
            regionSelector: regionSelector
        )

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.viewModel.lastError != nil)
    }

    @Test func captureCancel_selectionCancelled_noError() async throws {
        guard isPermissionGranted() else { return }

        // regionSelector returns nil (default) — simulates user cancellation
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = nil

        let result = makeViewModel(regionSelector: regionSelector)

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(result.viewModel.lastError == nil)
        #expect(result.viewModel.isCapturing == false)
    }

}

// MARK: - Guard Paths

extension AppViewModelTests {
    @Test func startCapture_ignoresDuplicateCapture() async throws {
        guard isPermissionGranted() else { return }

        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = nil

        let result = makeViewModel(regionSelector: regionSelector)

        // First capture — completes quickly since regionSelector returns nil
        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        let countAfterFirst = regionSelector.selectRegionCallCount

        // Immediate second call — cooldown (500ms) should block it
        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        #expect(regionSelector.selectRegionCallCount == countAfterFirst)
    }

    @Test func startCapture_respectsCooldownPeriod() async throws {
        guard isPermissionGranted() else { return }

        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = nil

        let result = makeViewModel(regionSelector: regionSelector)

        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        // Immediately try a second capture — within 500ms cooldown
        result.viewModel.startCapture()
        try await waitForCaptureCompletion(result.viewModel)

        // Only one selectRegion call should have occurred due to cooldown
        #expect(regionSelector.selectRegionCallCount == 1)
    }
}
