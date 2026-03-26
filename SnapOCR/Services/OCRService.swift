import AppKit
import os
import VisionKit

enum OCRService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "OCRService")
    /// Shared analyzer instance reused across requests to avoid repeated initialization cost.
    /// ImageAnalyzer is documented as safe to reuse across multiple analysis calls.
    private static let analyzer = ImageAnalyzer()

    static func recognizeText(from image: CGImage) async throws -> String {
        logger.info("Image size: \(image.width, privacy: .public)x\(image.height, privacy: .public)")

        let nsImage = NSImage(
            cgImage: image,
            size: NSSize(width: image.width, height: image.height)
        )
        let configuration = ImageAnalyzer.Configuration([.text])

        let analysis = try await analyzer.analyze(nsImage, orientation: .up, configuration: configuration)
        let transcript = analysis.transcript

        logger.info("Recognized text (\(transcript.count, privacy: .public) chars): '\(transcript, privacy: .private)'")

        return transcript
    }
}
