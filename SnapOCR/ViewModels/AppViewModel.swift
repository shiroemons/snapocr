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
    private let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "AppViewModel")
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
            logger.warning("Screen capture permission not granted")
            lastError = String(localized: "Screen recording permission is required.")
            permissionService.openSystemSettings()
            isCapturing = false
            return
        }

        lastError = nil
        defer { isCapturing = false }

        do {
            logger.info("Starting region selection")
            guard let selection = await SelectionOverlayWindow.selectRegion() else {
                logger.info("Region selection cancelled by user")
                return // User cancelled
            }
            logger.info("Region selected: \(String(describing: selection.rect), privacy: .public)")

            let image = try await CaptureService.captureRegion(
                selection.rect,
                displayID: selection.displayID,
                screenSize: selection.screenSize,
                scaleFactor: selection.scaleFactor
            )
            logger.info("Screen capture completed")

            let text = try await OCRService.recognizeText(from: image)
            logger.info("OCR completed: \(text.count) characters recognized")

            guard !text.isEmpty else {
                logger.warning("OCR result is empty")
                lastError = String(localized: "No text was recognized.")
                return
            }

            _ = ClipboardService.copy(text)
            logger.info("Text copied to clipboard successfully")
        } catch {
            logger.error("Capture failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
    }
}
