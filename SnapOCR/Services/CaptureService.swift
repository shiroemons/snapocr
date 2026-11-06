import AppKit
import CoreGraphics
import os
@preconcurrency import ScreenCaptureKit

struct CaptureService: CaptureServiceProtocol {
    private static let logger = Logger(category: "CaptureService")

    /// ScreenCaptureKit に渡す切り出し範囲（ディスプレイ左上原点のポイント）と出力サイズ。
    struct Geometry: Equatable {
        let sourceRect: CGRect
        let pixelWidth: Int
        let pixelHeight: Int
    }

    func captureRegion(
        _ rect: CGRect,
        displayID: CGDirectDisplayID,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) async throws -> CGImage {
        guard let geometry = Self.geometry(for: rect, screenSize: screenSize, scaleFactor: scaleFactor) else {
            Self.logger.error("Invalid capture region: \(String(describing: rect), privacy: .private)")
            throw CaptureError.invalidRegion
        }

        let content = try await SCShareableContent.current
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.noDisplay
        }

        // オーバーレイが消え切る前のキャプチャや、表示中のトーストの写り込みを防ぐ。
        // 履歴や設定など通常のレベルのウィンドウは除外しない。除外すると見えていない背後の文字を認識してしまう
        let processID = ProcessInfo.processInfo.processIdentifier
        let ownFloatingWindows = content.windows.filter {
            $0.owningApplication?.processID == processID && $0.windowLayer != NSWindow.Level.normal.rawValue
        }
        let filter = SCContentFilter(display: display, excludingWindows: ownFloatingWindows)

        // 画面全体を撮ってから切り抜くと、切り抜いた画像が元の全画面バッファを保持し続ける
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = geometry.sourceRect
        configuration.width = geometry.pixelWidth
        configuration.height = geometry.pixelHeight
        configuration.captureResolution = .best
        configuration.showsCursor = false

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        Self.logger.info("Captured image size: \(image.width, privacy: .public)x\(image.height, privacy: .public)")
        return image
    }

    /// AppKit 座標（左下原点）の選択範囲を、キャプチャに使う範囲と出力サイズへ変換する。
    /// 範囲が画面と重ならない場合や倍率が不正な場合は nil を返す。
    nonisolated static func geometry(
        for rect: CGRect,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) -> Geometry? {
        guard scaleFactor > 0 else { return nil }
        // sourceRect はディスプレイの範囲内でなければならない
        let visibleRect = rect.intersection(CGRect(origin: .zero, size: screenSize))
        guard !visibleRect.isEmpty else { return nil }

        let top = screenSize.height - visibleRect.maxY
        // 端数のある範囲は物理ピクセルの境界まで広げ、文字の端が欠けないようにする
        let minX = (visibleRect.minX * scaleFactor).rounded(.down)
        let minY = (top * scaleFactor).rounded(.down)
        let maxX = (visibleRect.maxX * scaleFactor).rounded(.up)
        let maxY = ((top + visibleRect.height) * scaleFactor).rounded(.up)

        return Geometry(
            sourceRect: CGRect(
                x: minX / scaleFactor,
                y: minY / scaleFactor,
                width: (maxX - minX) / scaleFactor,
                height: (maxY - minY) / scaleFactor
            ),
            pixelWidth: Int(maxX - minX),
            pixelHeight: Int(maxY - minY)
        )
    }
}

enum CaptureError: LocalizedError {
    case noDisplay
    case captureFailure
    case invalidRegion

    var errorDescription: String? {
        localizedDescription(bundle: .main)
    }

    func localizedDescription(bundle: Bundle) -> String {
        switch self {
        case .noDisplay:
            String(
                localized: "No display found",
                bundle: bundle,
                comment: "Error when target display is unavailable"
            )
        case .captureFailure:
            String(
                localized: "Screen capture failed",
                bundle: bundle,
                comment: "Error when screen capture operation fails"
            )
        case .invalidRegion:
            String(
                localized: "Invalid capture region",
                bundle: bundle,
                comment: "Error when capture region has invalid dimensions"
            )
        }
    }
}
