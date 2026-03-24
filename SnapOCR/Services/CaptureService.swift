import AppKit
@preconcurrency import ScreenCaptureKit

enum CaptureService {
    /// Capture a rectangular region of the screen
    @MainActor
    static func captureRegion(_ rect: CGRect) async throws -> CGImage {
        let content = try await SCShareableContent.current

        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }

        let filter = SCContentFilter(
            display: display,
            excludingWindows: []
        )

        let config = buildConfiguration(for: rect)

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }

    /// Build SCStreamConfiguration for the given region
    private static func buildConfiguration(for rect: CGRect) -> SCStreamConfiguration {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
        let config = SCStreamConfiguration()
        config.sourceRect = rect
        config.width = Int(rect.width * scaleFactor)
        config.height = Int(rect.height * scaleFactor)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false
        return config
    }
}

enum CaptureError: LocalizedError {
    case noDisplay
    case captureFailure

    var errorDescription: String? {
        switch self {
        case .noDisplay:
            return String(localized: "No display found")
        case .captureFailure:
            return String(localized: "Screen capture failed")
        }
    }
}
