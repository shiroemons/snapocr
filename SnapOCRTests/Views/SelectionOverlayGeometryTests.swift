import CoreGraphics
@testable import SnapOCR
import Testing

@Suite("SelectionOverlay Geometry Tests")
struct SelectionOverlayGeometryTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    private func selectionRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        SelectionOverlayView.selectionRect(from: start, to: end, in: bounds)
    }

    // MARK: - ドラッグの方向

    @Test func forwardDragSpansFromStartToEnd() {
        let rect = selectionRect(from: CGPoint(x: 100, y: 200), to: CGPoint(x: 400, y: 600))
        #expect(rect == CGRect(x: 100, y: 200, width: 300, height: 400))
    }

    @Test func reverseDragGivesSameRectAsForwardDrag() {
        let rect = selectionRect(from: CGPoint(x: 400, y: 600), to: CGPoint(x: 100, y: 200))
        #expect(rect == CGRect(x: 100, y: 200, width: 300, height: 400))
    }

    @Test func dragReversedOnOneAxisGivesSameRect() {
        let rect = selectionRect(from: CGPoint(x: 400, y: 200), to: CGPoint(x: 100, y: 600))
        #expect(rect == CGRect(x: 100, y: 200, width: 300, height: 400))
    }

    @Test func dragCoveringWholeBoundsIsUnchanged() {
        let rect = selectionRect(from: .zero, to: CGPoint(x: 1000, y: 800))
        #expect(rect == bounds)
    }

    @Test func clickWithoutMovementIsEmpty() {
        let rect = selectionRect(from: CGPoint(x: 100, y: 200), to: CGPoint(x: 100, y: 200))
        #expect(rect.isEmpty)
    }

    // MARK: - bounds の外へのはみ出し

    @Test func dragPastRightEdgeStopsAtEdge() {
        let rect = selectionRect(from: CGPoint(x: 900, y: 200), to: CGPoint(x: 1500, y: 600))
        #expect(rect == CGRect(x: 900, y: 200, width: 100, height: 400))
    }

    @Test func dragPastLeftEdgeStopsAtEdge() {
        let rect = selectionRect(from: CGPoint(x: 100, y: 200), to: CGPoint(x: -500, y: 600))
        #expect(rect == CGRect(x: 0, y: 200, width: 100, height: 400))
    }

    @Test func dragPastTopEdgeStopsAtEdge() {
        let rect = selectionRect(from: CGPoint(x: 100, y: 700), to: CGPoint(x: 400, y: 1200))
        #expect(rect == CGRect(x: 100, y: 700, width: 300, height: 100))
    }

    @Test func dragPastBottomEdgeStopsAtEdge() {
        let rect = selectionRect(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 400, y: -300))
        #expect(rect == CGRect(x: 100, y: 0, width: 300, height: 100))
    }

    @Test func dragPastCornerStopsAtBothEdges() {
        let rect = selectionRect(from: CGPoint(x: 900, y: 700), to: CGPoint(x: 1500, y: 1200))
        #expect(rect == CGRect(x: 900, y: 700, width: 100, height: 100))
    }

    // MARK: - 完全に bounds の外

    @Test func dragEntirelyBeyondOneSideIsEmpty() {
        let rect = selectionRect(from: CGPoint(x: 1100, y: 200), to: CGPoint(x: 1500, y: 600))
        #expect(rect.isEmpty)
    }

    @Test func dragEntirelyBeyondCornerIsEmpty() {
        let rect = selectionRect(from: CGPoint(x: -500, y: -300), to: CGPoint(x: -100, y: -100))
        #expect(rect.isEmpty)
    }
}
