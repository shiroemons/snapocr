import CoreGraphics
import Foundation
@testable import SnapOCR
import Testing

@Suite("CaptureService Tests")
@MainActor
struct CaptureServiceTests {
    private typealias Geometry = CaptureService.Geometry

    private let screen = CGSize(width: 1920, height: 1080)

    // MARK: - Scale Factor

    @Test func geometryAtScale1() {
        let geometry = CaptureService.geometry(
            for: CGRect(x: 100, y: 200, width: 300, height: 400),
            screenSize: screen,
            scaleFactor: 1.0
        )
        #expect(geometry == Geometry(
            sourceRect: CGRect(x: 100, y: 480, width: 300, height: 400),
            pixelWidth: 300,
            pixelHeight: 400
        ))
    }

    @Test func geometryAtScale1Point5() {
        let geometry = CaptureService.geometry(
            for: CGRect(x: 100, y: 200, width: 300, height: 400),
            screenSize: screen,
            scaleFactor: 1.5
        )
        #expect(geometry == Geometry(
            sourceRect: CGRect(x: 100, y: 480, width: 300, height: 400),
            pixelWidth: 450,
            pixelHeight: 600
        ))
    }

    @Test func geometryAtScale2() {
        let geometry = CaptureService.geometry(
            for: CGRect(x: 50, y: 100, width: 200, height: 150),
            screenSize: CGSize(width: 1440, height: 900),
            scaleFactor: 2.0
        )
        #expect(geometry == Geometry(
            sourceRect: CGRect(x: 50, y: 650, width: 200, height: 150),
            pixelWidth: 400,
            pixelHeight: 300
        ))
    }

    // MARK: - Vertical Flip

    @Test func rectAtBottomOfScreenMapsToBottomOfCaptureSpace() {
        let geometry = CaptureService.geometry(
            for: CGRect(x: 0, y: 0, width: 100, height: 50),
            screenSize: screen,
            scaleFactor: 1.0
        )
        #expect(geometry?.sourceRect == CGRect(x: 0, y: 1030, width: 100, height: 50))
    }

    @Test func rectAtTopOfScreenMapsToTopOfCaptureSpace() {
        let geometry = CaptureService.geometry(
            for: CGRect(x: 0, y: 1030, width: 100, height: 50),
            screenSize: screen,
            scaleFactor: 1.0
        )
        #expect(geometry?.sourceRect == CGRect(x: 0, y: 0, width: 100, height: 50))
    }

    @Test func fullScreenRectCoversWholeDisplay() {
        let geometry = CaptureService.geometry(
            for: CGRect(origin: .zero, size: screen),
            screenSize: screen,
            scaleFactor: 2.0
        )
        #expect(geometry == Geometry(
            sourceRect: CGRect(origin: .zero, size: screen),
            pixelWidth: 3840,
            pixelHeight: 2160
        ))
    }

    // MARK: - Pixel Boundaries

    @Test func fractionalRectExpandsToPixelBoundaries() {
        let geometry = CaptureService.geometry(
            for: CGRect(x: 10.25, y: 20.25, width: 10.5, height: 10.5),
            screenSize: CGSize(width: 100, height: 100),
            scaleFactor: 2.0
        )
        #expect(geometry == Geometry(
            sourceRect: CGRect(x: 10, y: 69, width: 11, height: 11),
            pixelWidth: 22,
            pixelHeight: 22
        ))
    }

    // MARK: - Clipping

    @Test func rectOverlappingBottomLeftIsClipped() {
        let geometry = CaptureService.geometry(
            for: CGRect(x: -50, y: -50, width: 100, height: 100),
            screenSize: CGSize(width: 200, height: 100),
            scaleFactor: 1.0
        )
        #expect(geometry == Geometry(
            sourceRect: CGRect(x: 0, y: 50, width: 50, height: 50),
            pixelWidth: 50,
            pixelHeight: 50
        ))
    }

    @Test func rectOverlappingTopRightIsClipped() {
        let geometry = CaptureService.geometry(
            for: CGRect(x: 150, y: 80, width: 100, height: 100),
            screenSize: CGSize(width: 200, height: 100),
            scaleFactor: 2.0
        )
        #expect(geometry == Geometry(
            sourceRect: CGRect(x: 150, y: 0, width: 50, height: 20),
            pixelWidth: 100,
            pixelHeight: 40
        ))
    }

    // MARK: - No Geometry

    @Test(arguments: [
        CGRect(x: 5000, y: 5000, width: 100, height: 100),
        CGRect(x: -200, y: 0, width: 100, height: 100),
        // 画面の端に接しているだけで重なりがない範囲
        CGRect(x: 1920, y: 0, width: 100, height: 100),
        CGRect(x: 0, y: 0, width: 0, height: 100),
        CGRect(x: 0, y: 0, width: 100, height: 0),
    ])
    func rectWithoutVisibleAreaHasNoGeometry(rect: CGRect) {
        #expect(CaptureService.geometry(for: rect, screenSize: screen, scaleFactor: 2.0) == nil)
    }

    @Test(arguments: [CGFloat(0), -1])
    func invalidScaleFactorHasNoGeometry(scaleFactor: CGFloat) {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        #expect(CaptureService.geometry(for: rect, screenSize: screen, scaleFactor: scaleFactor) == nil)
    }

    // MARK: - Invalid Region Errors

    /// ここで渡す範囲はすべて `geometry` が nil を返すので、実際のキャプチャには進まない。
    @Test(arguments: [
        (CGRect(x: 0, y: 0, width: 0, height: 100), CGFloat(2)),
        (CGRect(x: 0, y: 0, width: 100, height: 0), CGFloat(2)),
        (CGRect(x: 0, y: 0, width: 100, height: 100), CGFloat(-1)),
        (CGRect(x: 0, y: 0, width: 100, height: 100), CGFloat(0)),
        (CGRect(x: 5000, y: 5000, width: 100, height: 100), CGFloat(2)),
    ])
    func invalidRegionThrows(rect: CGRect, scaleFactor: CGFloat) async {
        await #expect(throws: CaptureError.invalidRegion) {
            try await CaptureService().captureRegion(
                rect,
                displayID: 1,
                screenSize: screen,
                scaleFactor: scaleFactor
            )
        }
    }

    // MARK: - CaptureError Descriptions

    @Test(arguments: [
        (CaptureError.noDisplay, "ディスプレイが見つかりません"),
        (CaptureError.captureFailure, "画面キャプチャに失敗しました"),
        (CaptureError.invalidRegion, "無効なキャプチャ領域です"),
    ])
    func captureErrorIsTranslatedToJapanese(error: CaptureError, expected: String) throws {
        let bundle = try localizationBundle(for: "ja")
        #expect(error.localizedDescription(bundle: bundle) == expected)
    }

    @Test(arguments: [
        (CaptureError.noDisplay, "No display found"),
        (CaptureError.captureFailure, "Screen capture failed"),
        (CaptureError.invalidRegion, "Invalid capture region"),
    ])
    func captureErrorIsShownInEnglish(error: CaptureError, expected: String) throws {
        let bundle = try localizationBundle(for: "en")
        #expect(error.localizedDescription(bundle: bundle) == expected)
    }
}
