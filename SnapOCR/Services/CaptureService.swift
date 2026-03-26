import AppKit
import os
@preconcurrency import ScreenCaptureKit

enum CaptureService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "CaptureService")

    static func captureRegion(
        _ rect: CGRect,
        displayID: CGDirectDisplayID,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) async throws -> CGImage {
        guard rect.width > 0, rect.height > 0 else {
            logger.error("Invalid capture rect: \(String(describing: rect), privacy: .public)")
            throw CaptureError.invalidRegion
        }
        guard scaleFactor > 0 else {
            logger.error("Invalid scale factor: \(scaleFactor, privacy: .public)")
            throw CaptureError.invalidRegion
        }
        logger.info("Input rect: \(String(describing: rect), privacy: .public)")

        let content = try await SCShareableContent.current

        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = Int(CGFloat(display.width) * scaleFactor)
        config.height = Int(CGFloat(display.height) * scaleFactor)
        config.showsCursor = false

        let fullImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        // AppKit uses bottom-left origin; CG/ScreenCaptureKit uses top-left
        let cropRect = convertToCGCoordinates(
            rect: rect,
            screenHeight: screenSize.height,
            scaleFactor: scaleFactor
        )

        guard let croppedImage = fullImage.cropping(to: cropRect) else {
            logger.error("Cropping failed. cropRect: \(String(describing: cropRect), privacy: .public), image: \(fullImage.width, privacy: .public)x\(fullImage.height, privacy: .public)")
            throw CaptureError.captureFailure
        }

        logger.info("Captured image size: \(croppedImage.width, privacy: .public)x\(croppedImage.height, privacy: .public)")

        return croppedImage
    }

    /// Converts an AppKit coordinate rect (bottom-left origin) to a CG coordinate rect (top-left origin),
    /// applying the display scale factor.
    nonisolated static func convertToCGCoordinates(
        rect: CGRect,
        screenHeight: CGFloat,
        scaleFactor: CGFloat
    ) -> CGRect {
        CGRect(
            x: rect.origin.x * scaleFactor,
            y: (screenHeight - rect.origin.y - rect.height) * scaleFactor,
            width: rect.width * scaleFactor,
            height: rect.height * scaleFactor
        )
    }
}

enum CaptureError: LocalizedError {
    case noDisplay
    case captureFailure
    case invalidRegion

    var errorDescription: String? {
        switch self {
        case .noDisplay:
            return String(localized: "No display found", comment: "Error when target display is unavailable")
        case .captureFailure:
            return String(localized: "Screen capture failed", comment: "Error when screen capture operation fails")
        case .invalidRegion:
            return String(localized: "Invalid capture region", comment: "Error when capture region has invalid dimensions")
        }
    }
}
