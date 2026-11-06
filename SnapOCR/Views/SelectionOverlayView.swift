//
//  SelectionOverlayView.swift
//  SnapOCR
//

import AppKit
import Carbon.HIToolbox

nonisolated private enum Constants {
    static let backgroundAlpha: CGFloat = 0.01
    static let overlayAlpha: CGFloat = 0.3
    static let borderWidth: CGFloat = 1.0
    static let minimumSelectionSize: CGFloat = 2
    static let labelFontSize: CGFloat = 8
    // カーソル描画
    static let cursorSize: CGFloat = 30
    static let cursorLineWidth: CGFloat = 1.0
    static let cursorOutlineWidth: CGFloat = 3.0
    static let cursorCircleRadius: CGFloat = 7.0
    static let cursorDotRadius: CGFloat = 1.0
    static let cursorLineInset: CGFloat = 1.5
    static let focusReclaimInterval: Duration = .milliseconds(250)
}

final class SelectionOverlayView: NSView {
    var onSelectionCompleted: ((CGRect) -> Void)?
    var onSelectionCancelled: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: CGRect = .zero
    var mouseLocation: NSPoint = .zero

    /// 60fps でカーソルを強制設定するタイマー
    private var cursorTimer: Timer?
    private var lastFocusReclaim: ContinuousClock.Instant?

    private var cachedCursor: NSCursor?
    private var cachedMouseLocation: NSPoint = .zero
    private var cachedCurrentRect: CGRect = .zero

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard !currentRect.isEmpty else {
            NSColor.black.withAlphaComponent(Constants.backgroundAlpha).setFill()
            NSBezierPath.fill(bounds)
            return
        }

        let overlayPath = NSBezierPath()
        overlayPath.windingRule = .evenOdd
        overlayPath.append(NSBezierPath(rect: bounds))
        overlayPath.append(NSBezierPath(rect: currentRect))
        NSColor.black.withAlphaComponent(Constants.overlayAlpha).setFill()
        overlayPath.fill()

        NSColor.white.setStroke()
        let borderPath = NSBezierPath(rect: currentRect)
        borderPath.lineWidth = Constants.borderWidth
        borderPath.stroke()
    }

    /// クロスヘア + 座標テキストを含む動的カーソルを生成
    private func makeCursorWithLabel() -> NSCursor {
        if let cached = cachedCursor,
           mouseLocation == cachedMouseLocation,
           currentRect == cachedCurrentRect {
            return cached
        }

        let (line1, line2) = cursorLabelLines()
        let size1 = Self.labelString(line1, outlined: false).size()
        let size2 = Self.labelString(line2, outlined: false).size()
        let textHeight = size1.height
        let maxTextWidth = max(size1.width, size2.width)

        let crossSize = Constants.cursorSize
        let halfCross = crossSize / 2
        let textOffset: CGFloat = 2
        let imageWidth = crossSize + textOffset + maxTextWidth + 4
        let imageHeight = crossSize + textOffset + textHeight * 2
        let crossCenterX = halfCross
        let crossCenterY = imageHeight - halfCross
        let textX = crossCenterX + Constants.cursorCircleRadius + 2
        let text1Y = crossCenterY - textOffset - textHeight
        let text2Y = text1Y - textHeight

        // NSImage の描画ハンドラは任意のタイミングとスレッドで呼ばれ得る（NSImage.h）。
        // MainActor の分離を前提にしないよう @Sendable で非分離にし、作成時点の値だけを使う
        let imageSize = NSSize(width: imageWidth, height: imageHeight)
        let image = NSImage(size: imageSize, flipped: false) { @Sendable _ in
            Self.drawCrosshairSymbol(centerX: crossCenterX, centerY: crossCenterY, halfSize: halfCross)
            for outlined in [true, false] {
                Self.labelString(line1, outlined: outlined).draw(at: NSPoint(x: textX, y: text1Y))
                Self.labelString(line2, outlined: outlined).draw(at: NSPoint(x: textX, y: text2Y))
            }
            return true
        }

        cachedMouseLocation = mouseLocation
        cachedCurrentRect = currentRect
        let cursor = NSCursor(image: image, hotSpot: NSPoint(x: crossCenterX, y: imageHeight - crossCenterY))
        cachedCursor = cursor
        return cursor
    }

    /// Returns (line1, line2) label strings — coordinates when idle, dimensions when dragging.
    private func cursorLabelLines() -> (String, String) {
        let (first, second) = currentRect.isEmpty
            ? (Int(mouseLocation.x), Int(bounds.height - mouseLocation.y))
            : (Int(currentRect.width), Int(currentRect.height))
        return (first.formatted(.number), second.formatted(.number))
    }

    nonisolated private static func labelString(_ text: String, outlined: Bool) -> NSAttributedString {
        let font = NSFont.monospacedDigitSystemFont(ofSize: Constants.labelFontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = outlined
            ? [
                .font: font,
                .foregroundColor: NSColor.white,
                .strokeColor: NSColor.white,
                .strokeWidth: NSNumber(value: -4.0)
            ]
            : [.font: font, .foregroundColor: NSColor.black]
        return NSAttributedString(string: text, attributes: attributes)
    }

    /// Draws the grey outline, black crosshair lines, circle ring, and centre dot.
    nonisolated private static func drawCrosshairSymbol(centerX: CGFloat, centerY: CGFloat, halfSize: CGFloat) {
        let inset = Constants.cursorLineInset
        let circleRadius = Constants.cursorCircleRadius

        // グレーの枠
        NSColor.gray.withAlphaComponent(0.5).setStroke()
        let outlinePath = NSBezierPath()
        outlinePath.lineWidth = Constants.cursorOutlineWidth
        outlinePath.lineCapStyle = .round
        outlinePath.move(to: NSPoint(x: centerX, y: centerY - halfSize))
        outlinePath.line(to: NSPoint(x: centerX, y: centerY + halfSize))
        outlinePath.move(to: NSPoint(x: centerX - halfSize, y: centerY))
        outlinePath.line(to: NSPoint(x: centerX + halfSize, y: centerY))
        outlinePath.stroke()

        // 黒い十字線
        NSColor.black.setStroke()
        let crossPath = NSBezierPath()
        crossPath.lineWidth = Constants.cursorLineWidth
        crossPath.move(to: NSPoint(x: centerX, y: centerY - halfSize + inset))
        crossPath.line(to: NSPoint(x: centerX, y: centerY + halfSize - inset))
        crossPath.move(to: NSPoint(x: centerX - halfSize + inset, y: centerY))
        crossPath.line(to: NSPoint(x: centerX + halfSize - inset, y: centerY))
        crossPath.stroke()

        // グレーの中央円リング
        NSColor.gray.withAlphaComponent(0.5).setStroke()
        let circlePath = NSBezierPath(ovalIn: NSRect(
            x: centerX - circleRadius, y: centerY - circleRadius,
            width: circleRadius * 2, height: circleRadius * 2
        ))
        circlePath.lineWidth = Constants.cursorLineWidth
        circlePath.stroke()

        // 中心の白いドット
        NSColor.white.setFill()
        let dotRadius = Constants.cursorDotRadius
        NSBezierPath(ovalIn: NSRect(
            x: centerX - dotRadius, y: centerY - dotRadius,
            width: dotRadius * 2, height: dotRadius * 2
        )).fill()
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        mouseLocation = current
        currentRect = Self.selectionRect(from: start, to: current, in: bounds)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint else { return }
        let end = convert(event.locationInWindow, from: nil)
        let selectionRect = Self.selectionRect(from: start, to: end, in: bounds)

        startPoint = nil
        currentRect = .zero

        let isValidSelection = selectionRect.width > Constants.minimumSelectionSize
            && selectionRect.height > Constants.minimumSelectionSize
        if isValidSelection {
            onSelectionCompleted?(selectionRect)
        } else {
            onSelectionCancelled?()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            startPoint = nil
            currentRect = .zero
            needsDisplay = true
            onSelectionCancelled?()
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Cursor Management

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopCursorTimer()
        guard window != nil else { return }

        // .common モードで登録し、スペース遷移アニメーション中もタイマーが発火するようにする
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let win = self.window as? SelectionOverlayWindow else { return }

                self.reclaimFocusIfNeeded(of: win)

                let windowPoint = win.convertPoint(fromScreen: NSEvent.mouseLocation)
                self.mouseLocation = self.convert(windowPoint, from: nil)
                self.makeCursorWithLabel().set()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        cursorTimer = timer
    }

    override func mouseMoved(with event: NSEvent) {
        mouseLocation = convert(event.locationInWindow, from: nil)
        makeCursorWithLabel().set()
    }

    func refreshCursor() {
        makeCursorWithLabel().set()
    }

    func stopCursorTimer() {
        cursorTimer?.invalidate()
        cursorTimer = nil
    }

    /// Esc を受け取るためキーウィンドウは取り戻すが、システムのダイアログと奪い合わないよう頻度を抑える
    private func reclaimFocusIfNeeded(of overlayWindow: SelectionOverlayWindow) {
        guard !overlayWindow.isKeyWindow else { return }

        let now = ContinuousClock.now
        if let last = lastFocusReclaim, last.duration(to: now) < Constants.focusReclaimInterval {
            return
        }
        lastFocusReclaim = now
        overlayWindow.activateAndFocus()
    }

    // MARK: - Geometry

    /// 複数ディスプレイではドラッグが画面外へ出て座標が `bounds` の外になるため、選択範囲を `bounds` に切り詰める
    nonisolated static func selectionRect(from start: CGPoint, to end: CGPoint, in bounds: CGRect) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        ).intersection(bounds)
    }
}
