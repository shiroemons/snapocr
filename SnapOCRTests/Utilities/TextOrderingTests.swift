import CoreGraphics
import Testing
@testable import SnapOCR

@Suite("TextOrdering Tests")
@MainActor
struct TextOrderingTests {

    // MARK: - sortedText

    @Test func sortedTextFromEmptyObservations() {
        let result = TextOrdering.sortedText(from: [])
        #expect(result == "")
    }

    // MARK: - detectDirection (CGRect overload)

    @Test func detectHorizontalDirectionWhenWidthDominates() {
        let boxes: [CGRect] = [
            CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.05),
            CGRect(x: 0.1, y: 0.6, width: 0.4, height: 0.05),
            CGRect(x: 0.2, y: 0.4, width: 0.35, height: 0.05)
        ]
        #expect(TextOrdering.detectDirection(from: boxes) == .horizontal)
    }

    @Test func detectVerticalDirectionWhenHeightDominates() {
        // height > width * 1.5 triggers vertical count
        let boxes: [CGRect] = [
            CGRect(x: 0.8, y: 0.1, width: 0.05, height: 0.3),
            CGRect(x: 0.6, y: 0.1, width: 0.05, height: 0.4),
            CGRect(x: 0.4, y: 0.1, width: 0.05, height: 0.35)
        ]
        #expect(TextOrdering.detectDirection(from: boxes) == .vertical)
    }

    @Test func detectHorizontalDirectionWhenMixed() {
        // 2 horizontal, 1 vertical → horizontal wins (not strictly greater)
        let boxes: [CGRect] = [
            CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.05),  // horizontal
            CGRect(x: 0.1, y: 0.6, width: 0.4, height: 0.05),  // horizontal
            CGRect(x: 0.8, y: 0.1, width: 0.05, height: 0.3)   // vertical
        ]
        #expect(TextOrdering.detectDirection(from: boxes) == .horizontal)
    }

    @Test func detectVerticalDirectionWhenVerticalMajority() {
        // 1 horizontal, 2 vertical → vertical wins
        let boxes: [CGRect] = [
            CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.05),  // horizontal
            CGRect(x: 0.8, y: 0.1, width: 0.05, height: 0.3),  // vertical
            CGRect(x: 0.6, y: 0.1, width: 0.05, height: 0.4)   // vertical
        ]
        #expect(TextOrdering.detectDirection(from: boxes) == .vertical)
    }

    @Test func detectHorizontalDirectionFromEmptyBoxes() {
        // Empty input: both counts are 0, verticalCount > horizontalCount is false → horizontal
        let boxes: [CGRect] = []
        #expect(TextOrdering.detectDirection(from: boxes) == .horizontal)
    }

    @Test func detectBoundaryCase() {
        // height == width * 1.5 → not strictly greater → counts as horizontal
        let box = CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.3) // height == width * 1.5
        #expect(TextOrdering.detectDirection(from: [box]) == .horizontal)
    }

    // MARK: - Parameterized direction tests

    @Test(arguments: [
        // (width, height, expectedDirection)
        (0.4, 0.05, TextOrdering.TextDirection.horizontal),  // wide → horizontal
        (0.05, 0.1, TextOrdering.TextDirection.vertical),    // height > width * 1.5 → vertical
        (0.1, 0.2, TextOrdering.TextDirection.vertical),     // height == width * 2 → vertical
        (0.2, 0.2, TextOrdering.TextDirection.horizontal),   // square → horizontal
        (0.2, 0.29, TextOrdering.TextDirection.horizontal)   // height < width * 1.5 → horizontal
    ])
    func detectDirectionParameterized(
        width: CGFloat,
        height: CGFloat,
        expected: TextOrdering.TextDirection
    ) {
        let box = CGRect(x: 0.1, y: 0.1, width: width, height: height)
        #expect(TextOrdering.detectDirection(from: [box]) == expected)
    }
}
