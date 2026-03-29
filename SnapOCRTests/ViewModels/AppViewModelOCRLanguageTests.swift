//
//  AppViewModelOCRLanguageTests.swift
//  SnapOCRTests
//

import CoreGraphics
import Foundation
@testable import SnapOCR
import Testing

@Suite("AppViewModel OCR Language Tests")
@MainActor
struct AppViewModelOCRLanguageTests {
    @Test func capturePassesOCRLanguagesToService() async throws {
        let permissionService = PermissionService()
        permissionService.checkPermission()
        guard permissionService.isScreenCapturePermitted else { return }

        let ocr = MockOCRService()
        let regionSelector = MockRegionSelector()
        regionSelector.selectRegionResult = SelectionResult(
            rect: CGRect(x: 0, y: 0, width: 100, height: 100),
            displayID: 1,
            screenSize: CGSize(width: 1920, height: 1080),
            scaleFactor: 2.0
        )

        let suiteName = "test.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create test UserDefaults")
            return
        }
        let settings = SettingsService(userDefaults: testDefaults)
        settings.ocrLanguages = ["ja", "en", "zh-Hans"]

        let viewModel = AppViewModel(
            permissionService: permissionService,
            settingsService: settings,
            ocrService: ocr,
            captureService: MockCaptureService(),
            clipboardService: MockClipboardService(),
            notificationService: MockNotificationService(),
            regionSelector: regionSelector
        )

        viewModel.startCapture()

        for _ in 0..<100 {
            if !viewModel.isCapturing { break }
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(ocr.lastRecognizeLanguages == ["ja", "en", "zh-Hans"])
    }
}
