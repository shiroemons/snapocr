import Vision

enum OCRService {
    /// Recognize text from a CGImage
    static func recognizeText(
        from image: CGImage,
        languages: [String] = ["ja", "en"]
    ) async throws -> String {
        let request = buildRequest(languages: languages)
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return ""
        }

        return TextOrdering.sortedText(from: observations)
    }

    /// Build a configured VNRecognizeTextRequest
    private static func buildRequest(languages: [String]) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        return request
    }
}
