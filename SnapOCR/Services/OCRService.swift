import CoreGraphics
import ImageIO
import os
import VisionKit

struct OCRService: OCRServiceProtocol {
    private static let logger = Logger(category: "OCRService")
    /// Shared analyzer instance reused across requests to avoid repeated initialization cost.
    /// ImageAnalyzer is documented as safe to reuse across multiple analysis calls.
    private static let analyzer = ImageAnalyzer()

    func recognizeText(from image: CGImage, languages: [String]) async throws -> String {
        Self.logger.info("Image size: \(image.width, privacy: .public)x\(image.height, privacy: .public)")
        Self.logger.info("Recognition languages: \(languages, privacy: .public)")

        var configuration = ImageAnalyzer.Configuration([.text])
        if !languages.isEmpty {
            configuration.locales = languages
        }

        let analysis = try await Self.analyzer.analyze(image, orientation: .up, configuration: configuration)
        let transcript = analysis.transcript

        // 認識結果にはパスワードなどの機微情報が含まれ得るので、本文はログに残さない
        Self.logger.info("Recognized \(transcript.count, privacy: .public) characters")

        return transcript
    }
}
