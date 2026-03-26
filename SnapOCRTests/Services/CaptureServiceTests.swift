import AppKit
import Testing
@testable import SnapOCR

@Suite("CaptureService Tests")
struct CaptureServiceTests {
    // MARK: - Coordinate Conversion

    @Test func convertToCGCoordinatesBasicConversion() {
        // AppKit rect: origin at bottom-left (100, 200), size 300x400
        // Screen height: 1080, scale factor: 1.0
        let rect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let result = CaptureService.convertToCGCoordinates(
            rect: rect,
            screenHeight: 1080,
            scaleFactor: 1.0
        )
        // CG y = (1080 - 200 - 400) * 1.0 = 480
        #expect(result.origin.x == 100)
        #expect(result.origin.y == 480)
        #expect(result.width == 300)
        #expect(result.height == 400)
    }

    @Test func convertToCGCoordinatesWithScaleFactor() {
        let rect = CGRect(x: 50, y: 100, width: 200, height: 150)
        let result = CaptureService.convertToCGCoordinates(
            rect: rect,
            screenHeight: 900,
            scaleFactor: 2.0
        )
        // x = 50 * 2 = 100
        // y = (900 - 100 - 150) * 2 = 650 * 2 = 1300
        // width = 200 * 2 = 400
        // height = 150 * 2 = 300
        #expect(result.origin.x == 100)
        #expect(result.origin.y == 1300)
        #expect(result.width == 400)
        #expect(result.height == 300)
    }

    @Test func convertToCGCoordinatesOriginAtBottom() {
        // Rect at very bottom of screen (y=0 in AppKit)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let result = CaptureService.convertToCGCoordinates(
            rect: rect,
            screenHeight: 1080,
            scaleFactor: 1.0
        )
        // CG y = (1080 - 0 - 50) * 1 = 1030
        #expect(result.origin.x == 0)
        #expect(result.origin.y == 1030)
        #expect(result.width == 100)
        #expect(result.height == 50)
    }

    @Test func convertToCGCoordinatesOriginAtTop() {
        // Rect at very top of screen (y + height = screenHeight in AppKit)
        let rect = CGRect(x: 0, y: 1030, width: 100, height: 50)
        let result = CaptureService.convertToCGCoordinates(
            rect: rect,
            screenHeight: 1080,
            scaleFactor: 1.0
        )
        // CG y = (1080 - 1030 - 50) * 1 = 0
        #expect(result.origin.x == 0)
        #expect(result.origin.y == 0)
        #expect(result.width == 100)
        #expect(result.height == 50)
    }

    @Test func convertToCGCoordinatesFullScreen() {
        let rect = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let result = CaptureService.convertToCGCoordinates(
            rect: rect,
            screenHeight: 1080,
            scaleFactor: 1.0
        )
        #expect(result.origin.x == 0)
        #expect(result.origin.y == 0)
        #expect(result.width == 1920)
        #expect(result.height == 1080)
    }

    // MARK: - Invalid Region Errors

    @Test func invalidRegionWithZeroWidth() async throws {
        let rect = CGRect(x: 0, y: 0, width: 0, height: 100)
        await #expect(throws: CaptureError.self) {
            try await CaptureService.captureRegion(
                rect,
                displayID: CGMainDisplayID(),
                screenSize: CGSize(width: 1920, height: 1080),
                scaleFactor: 2.0
            )
        }
    }

    @Test func invalidRegionWithZeroHeight() async throws {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 0)
        await #expect(throws: CaptureError.self) {
            try await CaptureService.captureRegion(
                rect,
                displayID: CGMainDisplayID(),
                screenSize: CGSize(width: 1920, height: 1080),
                scaleFactor: 2.0
            )
        }
    }

    @Test func invalidRegionWithNegativeScaleFactor() async throws {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        await #expect(throws: CaptureError.self) {
            try await CaptureService.captureRegion(
                rect,
                displayID: CGMainDisplayID(),
                screenSize: CGSize(width: 1920, height: 1080),
                scaleFactor: -1.0
            )
        }
    }
}
