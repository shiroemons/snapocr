import CoreGraphics
import Foundation
@testable import SnapOCR

// MARK: - MockOCRService

final class MockOCRService: OCRServiceProtocol, @unchecked Sendable {
    var recognizeTextResult: String = "Mocked OCR text"
    var recognizeTextError: (any Error)?
    var recognizeTextCallCount = 0
    var lastRecognizeLanguages: [String]?

    func recognizeText(from image: CGImage, languages: [String]) async throws -> String {
        recognizeTextCallCount += 1
        lastRecognizeLanguages = languages
        if let error = recognizeTextError { throw error }
        return recognizeTextResult
    }
}

// MARK: - MockCaptureService

final class MockCaptureService: CaptureServiceProtocol, @unchecked Sendable {
    var captureRegionResult: CGImage?
    var captureRegionError: (any Error)?
    var captureRegionCallCount = 0

    func captureRegion(
        _ rect: CGRect,
        displayID: CGDirectDisplayID,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) async throws -> CGImage {
        captureRegionCallCount += 1
        if let error = captureRegionError { throw error }
        if let result = captureRegionResult { return result }
        return createDummyImage()
    }

    private func createDummyImage() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage() else {
            fatalError("Failed to create 1x1 dummy CGImage for testing")
        }
        return image
    }
}

// MARK: - MockClipboardService

@MainActor
final class MockClipboardService: ClipboardServiceProtocol {
    var copyResult = true
    var copyCallCount = 0
    var lastCopiedText: String?

    func copy(_ text: String) -> Bool {
        copyCallCount += 1
        lastCopiedText = text
        return copyResult
    }
}

// MARK: - MockNotificationService

@MainActor
final class MockNotificationService: NotificationServiceProtocol {
    var notifySuccessCallCount = 0
    var lastNotifiedText: String?

    func notifySuccess(text: String, settings: SettingsService) {
        notifySuccessCallCount += 1
        lastNotifiedText = text
    }
}

// MARK: - MockRegionSelector

@MainActor
final class MockRegionSelector: RegionSelectorProtocol {
    var selectRegionResult: SelectionResult?
    var selectRegionCallCount = 0

    func selectRegion() async -> SelectionResult? {
        selectRegionCallCount += 1
        return selectRegionResult
    }
}
