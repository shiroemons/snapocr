//
//  AppViewModel.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import Foundation
import os
import Observation

@Observable
@MainActor
final class AppViewModel {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "AppViewModel")
    private let permissionService: PermissionService
    private let hotkeyService: HotkeyService

    private(set) var isCapturing = false
    private(set) var lastError: String?

    init(
        permissionService: PermissionService = PermissionService(),
        hotkeyService: HotkeyService = HotkeyService()
    ) {
        self.permissionService = permissionService
        self.hotkeyService = hotkeyService
    }

    func setup() {
        permissionService.checkPermission()
        hotkeyService.onHotkeyPressed = { [weak self] in
            self?.startCapture()
        }
        hotkeyService.register()
    }

    func teardown() {
        hotkeyService.unregister()
    }

    func startCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        Task {
            await performCapture()
        }
    }

    private func performCapture() async {
        permissionService.checkPermission()
        guard permissionService.isScreenCapturePermitted else {
            Self.logger.warning("Screen capture permission not granted")
            lastError = String(localized: "Screen recording permission is required.")
            permissionService.openSystemSettings()
            isCapturing = false
            return
        }

        lastError = nil
        defer { isCapturing = false }

        do {
            Self.logger.info("Starting region selection")
            guard let selection = await SelectionOverlayWindow.selectRegion() else {
                Self.logger.info("Region selection cancelled by user")
                return // User cancelled
            }
            Self.logger.info("Region selected: \(String(describing: selection.rect), privacy: .public)")

            let image = try await CaptureService.captureRegion(
                selection.rect,
                displayID: selection.displayID,
                screenSize: selection.screenSize,
                scaleFactor: selection.scaleFactor
            )
            Self.logger.info("Screen capture completed")

            let text = try await OCRService.recognizeText(from: image)
            Self.logger.info("OCR completed: \(text.count) characters recognized")

            guard !text.isEmpty else {
                Self.logger.warning("OCR result is empty")
                lastError = String(localized: "No text was recognized.")
                return
            }

            if ClipboardService.copy(text) {
                Self.logger.info("Text copied to clipboard successfully")
            } else {
                Self.logger.warning("Failed to copy text to clipboard")
            }
        } catch {
            Self.logger.error("Capture failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
    }
}
