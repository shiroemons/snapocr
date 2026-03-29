//
//  ServiceProtocols.swift
//  SnapOCR
//

import CoreGraphics

// MARK: - OCRServiceProtocol

protocol OCRServiceProtocol: Sendable {
    func recognizeText(from image: CGImage, languages: [String]) async throws -> String
}

struct DefaultOCRService: OCRServiceProtocol {
    func recognizeText(from image: CGImage, languages: [String]) async throws -> String {
        try await OCRService.recognizeText(from: image, languages: languages)
    }
}

// MARK: - CaptureServiceProtocol

protocol CaptureServiceProtocol: Sendable {
    func captureRegion(
        _ rect: CGRect,
        displayID: CGDirectDisplayID,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) async throws -> CGImage
}

struct DefaultCaptureService: CaptureServiceProtocol {
    func captureRegion(
        _ rect: CGRect,
        displayID: CGDirectDisplayID,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) async throws -> CGImage {
        try await CaptureService.captureRegion(
            rect,
            displayID: displayID,
            screenSize: screenSize,
            scaleFactor: scaleFactor
        )
    }
}

// MARK: - ClipboardServiceProtocol

@MainActor
protocol ClipboardServiceProtocol: Sendable {
    func copy(_ text: String) -> Bool
}

@MainActor
struct DefaultClipboardService: ClipboardServiceProtocol {
    func copy(_ text: String) -> Bool {
        ClipboardService.copy(text)
    }
}

// MARK: - NotificationServiceProtocol

@MainActor
protocol NotificationServiceProtocol: Sendable {
    func notifySuccess(text: String, settings: SettingsService)
}

@MainActor
struct DefaultNotificationService: NotificationServiceProtocol {
    func notifySuccess(text: String, settings: SettingsService) {
        NotificationService.notifySuccess(text: text, settings: settings)
    }
}

// MARK: - RegionSelectorProtocol

@MainActor
protocol RegionSelectorProtocol: Sendable {
    func selectRegion() async -> SelectionResult?
}

@MainActor
struct DefaultRegionSelector: RegionSelectorProtocol {
    func selectRegion() async -> SelectionResult? {
        await SelectionOverlayWindow.selectRegion()
    }
}
