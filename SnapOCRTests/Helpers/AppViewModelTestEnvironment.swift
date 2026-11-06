import CoreGraphics
@testable import SnapOCR

/// `AppViewModel` のテストに必要なモックと設定の一式。
@MainActor
struct AppViewModelTestEnvironment {
    static let sampleSelection = SelectionResult(
        rect: CGRect(x: 10, y: 20, width: 30, height: 40),
        displayID: 7,
        screenSize: CGSize(width: 1920, height: 1080),
        scaleFactor: 2.0
    )

    let testDefaults = TestUserDefaults()
    let settings: SettingsService
    let permission = MockPermissionService()
    let hotkey = MockHotkeyService()
    let ocr = MockOCRService()
    let capture = MockCaptureService()
    let clipboard = MockClipboardService()
    let notification = MockNotificationService()
    let regionSelector = MockRegionSelector()

    init() {
        settings = SettingsService(userDefaults: testDefaults)
        regionSelector.selectRegionResult = Self.sampleSelection
    }

    /// `AppViewModel` の既定引数は実機のサービスなので、ここですべて明示的に渡す。
    func makeViewModel(
        settings: SettingsService? = nil,
        historyService: HistoryService? = nil,
        captureCooldown: Duration = .zero
    ) -> AppViewModel {
        AppViewModel(
            permissionService: permission,
            hotkeyService: hotkey,
            settingsService: settings ?? self.settings,
            historyService: historyService,
            ocrService: ocr,
            captureService: capture,
            clipboardService: clipboard,
            notificationService: notification,
            regionSelector: regionSelector,
            captureCooldown: captureCooldown
        )
    }
}

extension AppViewModel {
    func captureAndWait() async {
        startCapture()
        await captureTask?.value
    }
}
