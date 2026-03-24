import Vision

enum TextOrdering {
    /// Detected text direction
    enum TextDirection {
        case horizontal
        case vertical
    }

    static func sortedText(from observations: [VNRecognizedTextObservation]) -> String {
        guard !observations.isEmpty else { return "" }

        let direction = detectDirection(observations)
        let sorted = sort(observations, direction: direction)

        return sorted.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
    }

    static func detectDirection(from boundingBoxes: [CGRect]) -> TextDirection {
        var horizontalCount = 0
        var verticalCount = 0

        for box in boundingBoxes {
            if box.height > box.width * 1.5 {
                verticalCount += 1
            } else {
                horizontalCount += 1
            }
        }

        return verticalCount > horizontalCount ? .vertical : .horizontal
    }

    static func detectDirection(_ observations: [VNRecognizedTextObservation]) -> TextDirection {
        detectDirection(from: observations.map(\.boundingBox))
    }

    /// Sort observations by reading order
    /// - Horizontal: top→bottom, left→right
    /// - Vertical: right→left, top→bottom
    static func sort(
        _ observations: [VNRecognizedTextObservation],
        direction: TextDirection
    ) -> [VNRecognizedTextObservation] {
        switch direction {
        case .horizontal:
            return sortHorizontal(observations)
        case .vertical:
            return sortVertical(observations)
        }
    }

    /// Vision boundingBox origin is bottom-left, Y increases upward
    private static func sortHorizontal(
        _ observations: [VNRecognizedTextObservation]
    ) -> [VNRecognizedTextObservation] {
        observations.sorted { lhs, rhs in
            let lhsY = lhs.boundingBox.midY
            let rhsY = rhs.boundingBox.midY
            let lineHeight = max(lhs.boundingBox.height, rhs.boundingBox.height)

            if abs(lhsY - rhsY) < lineHeight * 0.5 {
                return lhs.boundingBox.minX < rhs.boundingBox.minX
            }
            return lhsY > rhsY
        }
    }

    private static func sortVertical(
        _ observations: [VNRecognizedTextObservation]
    ) -> [VNRecognizedTextObservation] {
        observations.sorted { lhs, rhs in
            let lhsX = lhs.boundingBox.midX
            let rhsX = rhs.boundingBox.midX
            let colWidth = max(lhs.boundingBox.width, rhs.boundingBox.width)

            if abs(lhsX - rhsX) < colWidth * 0.5 {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }
            return lhsX > rhsX
        }
    }
}
