//
//  ServiceProtocols.swift
//  SnapOCR
//

import CoreGraphics

// MARK: - OCRServiceProtocol

protocol OCRServiceProtocol {
    func recognizeText(from image: CGImage, languages: [String]) async throws -> String
}

// MARK: - CaptureServiceProtocol

protocol CaptureServiceProtocol {
    func captureRegion(
        _ rect: CGRect,
        displayID: CGDirectDisplayID,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) async throws -> CGImage
}

// MARK: - ClipboardServiceProtocol

protocol ClipboardServiceProtocol {
    func copy(_ text: String) -> Bool
}

// MARK: - NotificationServiceProtocol

protocol NotificationServiceProtocol {
    func notifySuccess(text: String, settings: SettingsService)
    func notifyFailure(message: String)
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
