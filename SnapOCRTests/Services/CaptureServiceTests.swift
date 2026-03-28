import AppKit
@testable import SnapOCR
import Testing

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

    @Test func invalidRegionWithZeroScaleFactor() async throws {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        await #expect(throws: CaptureError.self) {
            try await CaptureService.captureRegion(
                rect,
                displayID: CGMainDisplayID(),
                screenSize: CGSize(width: 1920, height: 1080),
                scaleFactor: 0
            )
        }
    }

    // MARK: - Coordinate Conversion Edge Cases

    @Test func convertToCGCoordinatesWithFractionalScaleFactor() {
        let rect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let result = CaptureService.convertToCGCoordinates(
            rect: rect,
            screenHeight: 1080,
            scaleFactor: 1.5
        )
        // x = 100 * 1.5 = 150
        // y = (1080 - 200 - 400) * 1.5 = 480 * 1.5 = 720
        // width = 300 * 1.5 = 450
        // height = 400 * 1.5 = 600
        #expect(result.origin.x == 150)
        #expect(result.origin.y == 720)
        #expect(result.width == 450)
        #expect(result.height == 600)
    }

    @Test func convertToCGCoordinatesWithZeroSizeRect() {
        let rect = CGRect(x: 500, y: 300, width: 0, height: 0)
        let result = CaptureService.convertToCGCoordinates(
            rect: rect,
            screenHeight: 1080,
            scaleFactor: 2.0
        )
        // x = 500 * 2 = 1000
        // y = (1080 - 300 - 0) * 2 = 780 * 2 = 1560
        // width = 0, height = 0
        #expect(result.origin.x == 1000)
        #expect(result.origin.y == 1560)
        #expect(result.width == 0)
        #expect(result.height == 0)
    }

    // MARK: - CaptureError Descriptions

    @Test func captureErrorLocalizedDescriptionsAreNotEmpty() {
        let errors: [CaptureError] = [.noDisplay, .captureFailure, .invalidRegion]
        for error in errors {
            let description = error.localizedDescription(bundle: .main)
            #expect(!description.isEmpty, "CaptureError.\(error) should have a non-empty description")
        }
    }
}
