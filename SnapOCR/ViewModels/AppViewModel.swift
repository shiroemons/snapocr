//
//  AppViewModel.swift
//  SnapOCR
//

import Foundation
import Observation
import os

@MainActor
final class AppViewModel {
    private static let logger = Logger(category: "AppViewModel")
    private let permissionService: PermissionService
    private let hotkeyService: HotkeyService
    private let settingsService: SettingsService
    private let historyService: HistoryService?
    private let ocrService: any OCRServiceProtocol
    private let captureService: any CaptureServiceProtocol
    private let clipboardService: any ClipboardServiceProtocol
    private let notificationService: any NotificationServiceProtocol
    private let regionSelector: any RegionSelectorProtocol
    private let captureCooldown: Duration

    private var isTrackingActive = true

    private var bundle: Bundle { settingsService.localizationBundle }

    private(set) var isCapturing = false
    private(set) var captureTask: Task<Void, Never>?
    private var lastCaptureEndTime: ContinuousClock.Instant?

    init(
        permissionService: PermissionService = PermissionService(),
        hotkeyService: HotkeyService = HotkeyService(),
        settingsService: SettingsService = SettingsService(),
        historyService: HistoryService? = nil,
        ocrService: any OCRServiceProtocol = OCRService(),
        captureService: any CaptureServiceProtocol = CaptureService(),
        clipboardService: any ClipboardServiceProtocol = ClipboardService(),
        notificationService: any NotificationServiceProtocol = NotificationService(),
        regionSelector: any RegionSelectorProtocol = DefaultRegionSelector(),
        captureCooldown: Duration = .milliseconds(500)
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
        self.captureCooldown = captureCooldown
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

    // MARK: - Capture

    func startCapture() {
        guard !isCapturing, isCooldownElapsed else { return }
        isCapturing = true

        captureTask = Task {
            await performCapture()
        }
    }

    private var isCooldownElapsed: Bool {
        guard let lastCaptureEndTime else { return true }
        return ContinuousClock.Instant.now - lastCaptureEndTime > captureCooldown
    }

    private func performCapture() async {
        defer {
            lastCaptureEndTime = .now
            isCapturing = false
        }

        guard checkScreenCapturePermission() else { return }

        do {
            Self.logger.info("Starting region selection")
            guard let selection = await regionSelector.selectRegion() else {
                Self.logger.info("Region selection cancelled by user")
                return
            }

            let image = try await captureService.captureRegion(
                selection.rect,
                displayID: selection.displayID,
                screenSize: selection.screenSize,
                scaleFactor: selection.scaleFactor
            )
            Self.logger.info("Screen capture completed")

            let text = try await ocrService.recognizeText(from: image, languages: settingsService.ocrLanguages)
            Self.logger.info("OCR completed: \(text.count) characters recognized")
            try Task.checkCancellation()

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                Self.logger.warning("OCR result is empty")
                reportFailure(String(
                    localized: "No text was recognized.",
                    bundle: bundle,
                    comment: "Error message when OCR produces empty result"
                ))
                return
            }

            handleRecognizedText(text)
        } catch is CancellationError {
            Self.logger.info("Capture cancelled")
        } catch {
            Self.logger.error("Capture failed: \(error.localizedDescription, privacy: .public)")
            if let captureError = error as? CaptureError {
                reportFailure(captureError.localizedDescription(bundle: bundle))
            } else {
                reportFailure(error.localizedDescription)
            }
        }
    }

    /// Returns `true` if screen capture permission is granted; reports the failure and opens settings if not.
    private func checkScreenCapturePermission() -> Bool {
        permissionService.checkPermission()
        guard permissionService.isScreenCapturePermitted else {
            Self.logger.warning("Screen capture permission not granted")
            reportFailure(String(
                localized: "Screen recording permission is required.",
                bundle: bundle,
                comment: "Error message when screen recording permission is not granted"
            ))
            permissionService.openSystemSettings()
            return false
        }
        return true
    }

    private func handleRecognizedText(_ text: String) {
        if clipboardService.copy(text) {
            Self.logger.info("Text copied to clipboard successfully")
            notificationService.notifySuccess(text: text, settings: settingsService)
        } else {
            Self.logger.warning("Failed to copy text to clipboard")
            reportFailure(String(
                localized: "Could not copy the text to the clipboard.",
                bundle: bundle,
                comment: "Error message when writing to the clipboard fails"
            ))
        }
        // コピーに失敗しても認識結果を失わないよう、履歴には残す
        if settingsService.isHistoryEnabled {
            historyService?.addRecord(
                text: text,
                languages: settingsService.ocrLanguages,
                maxCount: settingsService.maxHistoryCount
            )
        }
    }

    private func reportFailure(_ message: String) {
        notificationService.notifyFailure(message: message)
    }
}
