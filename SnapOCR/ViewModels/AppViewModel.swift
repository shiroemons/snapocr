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
        isCapturing = true

        Task {
            await performCapture()
        }
    }

    private func performCapture() async {
        permissionService.checkPermission()
        guard permissionService.isScreenCapturePermitted else {
            lastError = String(localized: "Screen recording permission is required.")
            permissionService.openSystemSettings()
            isCapturing = false
            return
        }

        lastError = nil
        defer { isCapturing = false }

        do {
            guard let region = await SelectionOverlayWindow.selectRegion() else {
                return // User cancelled
            }

            let image = try await CaptureService.captureRegion(region)

            let text = try await OCRService.recognizeText(from: image)

            guard !text.isEmpty else {
                lastError = String(localized: "No text was recognized.")
                return
            }

            _ = ClipboardService.copy(text)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
