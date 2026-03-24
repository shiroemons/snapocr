//
//  AppViewModel.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import Foundation
import Observation

@Observable
@MainActor
final class AppViewModel {
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

        Task {
            await performCapture()
        }
    }

    private func performCapture() async {
        // 1. Check permission
        permissionService.checkPermission()
        guard permissionService.isScreenCapturePermitted else {
            lastError = String(localized: "Screen recording permission is required.")
            permissionService.openSystemSettings()
            return
        }

        isCapturing = true
        lastError = nil
        defer { isCapturing = false }

        do {
            // 2. Select region
            guard let region = await SelectionOverlayWindow.selectRegion() else {
                return // User cancelled
            }

            // 3. Capture screenshot
            let image = try await CaptureService.captureRegion(region)

            // 4. OCR
            let text = try await OCRService.recognizeText(from: image)

            guard !text.isEmpty else {
                lastError = String(localized: "No text was recognized.")
                return
            }

            // 5. Copy to clipboard
            _ = ClipboardService.copy(text)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
