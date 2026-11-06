//
//  ServiceProtocols.swift
//  SnapOCR
//

import CoreGraphics

protocol OCRServiceProtocol {
    func recognizeText(from image: CGImage, languages: [String]) async throws -> String
}

protocol CaptureServiceProtocol {
    func captureRegion(
        _ rect: CGRect,
        displayID: CGDirectDisplayID,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) async throws -> CGImage
}

protocol ClipboardServiceProtocol {
    func copy(_ text: String) -> Bool
}

protocol NotificationServiceProtocol {
    func notifySuccess(text: String, settings: SettingsService)
    func notifyFailure(message: String)
}

protocol RegionSelectorProtocol {
    func selectRegion() async -> SelectionResult?
}

struct DefaultRegionSelector: RegionSelectorProtocol {
    func selectRegion() async -> SelectionResult? {
        await SelectionOverlayWindow.selectRegion()
    }
}

protocol PermissionServiceProtocol: AnyObject {
    var isScreenCapturePermitted: Bool { get }
    func checkPermission()
    func openSystemSettings()
}

protocol HotkeyServiceProtocol: AnyObject {
    var onHotkeyPressed: (@MainActor () -> Void)? { get set }
    @discardableResult
    func updateHotkey(keyCode: UInt32, modifiers: UInt32) -> Bool
    func unregister()
}
