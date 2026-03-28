//
//  AppViewModel.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import Foundation
import Observation
import os

@Observable
@MainActor
final class AppViewModel {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "AppViewModel")
    private let permissionService: PermissionService
    private let hotkeyService: HotkeyService
    private let settingsService: SettingsService
    private let historyService: HistoryService?
    private let ocrService: any OCRServiceProtocol
    private let captureService: any CaptureServiceProtocol
    private let clipboardService: any ClipboardServiceProtocol
    private let notificationService: any NotificationServiceProtocol
    private let regionSelector: any RegionSelectorProtocol

    private var isTrackingActive = true

    private var bundle: Bundle { settingsService.localizationBundle }

    private(set) var isCapturing = false
    private(set) var lastError: String?
    private var captureTask: Task<Void, Never>?
    private var lastCaptureEndTime: ContinuousClock.Instant = .now - .seconds(10)

    init(
        permissionService: PermissionService = PermissionService(),
        hotkeyService: HotkeyService = HotkeyService(),
        settingsService: SettingsService = SettingsService(),
        historyService: HistoryService? = nil,
        ocrService: any OCRServiceProtocol = DefaultOCRService(),
        captureService: any CaptureServiceProtocol = DefaultCaptureService(),
        clipboardService: any ClipboardServiceProtocol = DefaultClipboardService(),
        notificationService: any NotificationServiceProtocol = DefaultNotificationService(),
        regionSelector: any RegionSelectorProtocol = DefaultRegionSelector()
    ) {
        self.permissionService = permissionService
        self.hotkeyService = hotkeyService
        self.settingsService = settingsService
        self.historyService = historyService
        self.ocrService = ocrService
        self.captureService = captureService
        self.clipboardService = clipboardService
        self.notificationService = notificationService
        self.regionSelector = regionSelector
    }

    func setup() {
        isTrackingActive = true
        permissionService.checkPermission()
        hotkeyService.onHotkeyPressed = { [weak self] in
            self?.startCapture()
        }
        hotkeyService.updateHotkey(
            keyCode: settingsService.hotkeyKeyCode,
            modifiers: settingsService.hotkeyModifiers
        )
        trackHotkeySettingsChanges()
    }

    // MARK: - Settings Observation

    private func trackHotkeySettingsChanges() {
        withObservationTracking {
            _ = settingsService.hotkeyKeyCode
            _ = settingsService.hotkeyModifiers
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.isTrackingActive else { return }
                self.hotkeyService.updateHotkey(
                    keyCode: self.settingsService.hotkeyKeyCode,
                    modifiers: self.settingsService.hotkeyModifiers
                )
                self.trackHotkeySettingsChanges()
            }
        }
    }

    func teardown() {
        isTrackingActive = false
        captureTask?.cancel()
        captureTask = nil
        hotkeyService.unregister()
    }

    func startCapture() {
        guard !isCapturing,
              ContinuousClock.Instant.now - lastCaptureEndTime > .milliseconds(500) else { return }
        isCapturing = true

        captureTask = Task {
            await performCapture()
        }
    }

    private func performCapture() async {
        defer {
            lastCaptureEndTime = .now
            isCapturing = false
        }

        guard checkScreenCapturePermission() else { return }
        lastError = nil

        do {
            Self.logger.info("Starting region selection")
            guard let selection = await regionSelector.selectRegion() else {
                Self.logger.info("Region selection cancelled by user")
                return
            }
            Self.logger.info("Region selected: \(String(describing: selection.rect), privacy: .private)")

            let image = try await captureService.captureRegion(
                selection.rect,
                displayID: selection.displayID,
                screenSize: selection.screenSize,
                scaleFactor: selection.scaleFactor
            )
            Self.logger.info("Screen capture completed")

            let text = try await ocrService.recognizeText(from: image)
            Self.logger.info("OCR completed: \(text.count) characters recognized")

            guard !text.isEmpty else {
                Self.logger.warning("OCR result is empty")
                lastError = String(
                    localized: "No text was recognized.",
                    bundle: bundle,
                    comment: "Error message when OCR produces empty result"
                )
                return
            }

            handleRecognizedText(text)
        } catch {
            Self.logger.error("Capture failed: \(error.localizedDescription, privacy: .public)")
            if let captureError = error as? CaptureError {
                lastError = captureError.localizedDescription(bundle: bundle)
            } else {
                lastError = error.localizedDescription
            }
        }
    }

    /// Returns `true` if screen capture permission is granted; sets `lastError` and opens settings if not.
    private func checkScreenCapturePermission() -> Bool {
        permissionService.checkPermission()
        guard permissionService.isScreenCapturePermitted else {
            Self.logger.warning("Screen capture permission not granted")
            lastError = String(
                localized: "Screen recording permission is required.",
                bundle: bundle,
                comment: "Error message when screen recording permission is not granted"
            )
            permissionService.openSystemSettings()
            return false
        }
        return true
    }

    private func handleRecognizedText(_ text: String) {
        if clipboardService.copy(text) {
            Self.logger.info("Text copied to clipboard successfully")
            notificationService.notifySuccess(text: text, settings: settingsService)
            if settingsService.isHistoryEnabled {
                historyService?.addRecord(
                    text: text,
                    languages: settingsService.ocrLanguages,
                    maxCount: settingsService.maxHistoryCount
                )
            }
        } else {
            Self.logger.warning("Failed to copy text to clipboard")
        }
    }
}
