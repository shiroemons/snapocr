//
//  SelectionOverlayView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import AppKit
import Carbon.HIToolbox

private enum Constants {
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
}

final class SelectionOverlayView: NSView {
    var onSelectionCompleted: ((CGRect) -> Void)?
    var onSelectionCancelled: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: CGRect = .zero
    var mouseLocation: NSPoint = .zero

    /// タイマーが停止済みかどうか（DispatchQueue.main.async の残存ブロック対策）
    private var isStopped = false

    /// 60fps でカーソルを強制設定するタイマー
    private var cursorTimer: Timer?

    private var cachedCursor: NSCursor?
    private var cachedMouseLocation: NSPoint = .zero
    private var cachedCurrentRect: CGRect = .zero

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

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
        let font = NSFont.monospacedDigitSystemFont(ofSize: Constants.labelFontSize, weight: .bold)
        let fillAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
        let outlineAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.white,
            .strokeWidth: NSNumber(value: -4.0)
        ]

        let str1 = NSAttributedString(string: line1, attributes: fillAttributes)
        let str2 = NSAttributedString(string: line2, attributes: fillAttributes)
        let textHeight = str1.size().height
        let maxTextWidth = max(str1.size().width, str2.size().width)

        let crossSize = Constants.cursorSize
        let halfCross = crossSize / 2
        let textOffset: CGFloat = 2
        let imageWidth = crossSize + textOffset + maxTextWidth + 4
        let imageHeight = crossSize + textOffset + textHeight * 2
        let crossCenterX = halfCross
        let crossCenterY = imageHeight - halfCross

        let image = NSImage(size: NSSize(width: imageWidth, height: imageHeight))
        image.lockFocus()
        drawCrosshairSymbol(centerX: crossCenterX, centerY: crossCenterY, halfSize: halfCross)
        let labelContext = CursorLabelContext(
            line1: line1, line2: line2,
            str1: str1, str2: str2,
            outlineAttributes: outlineAttributes,
            textOffset: textOffset, textHeight: textHeight
        )
        drawCursorLabels(context: labelContext, centerX: crossCenterX, centerY: crossCenterY)
        image.unlockFocus()

        cachedMouseLocation = mouseLocation
        cachedCurrentRect = currentRect
        let cursor = NSCursor(image: image, hotSpot: NSPoint(x: crossCenterX, y: imageHeight - crossCenterY))
        cachedCursor = cursor
        return cursor
    }

    /// Returns (line1, line2) label strings — coordinates when idle, dimensions when dragging.
    private func cursorLabelLines() -> (String, String) {
        let formatter = Self.numberFormatter
        if currentRect.isEmpty {
            let screenX = Int(mouseLocation.x)
            let screenY = Int(bounds.height - mouseLocation.y)
            return (
                formatter.string(from: NSNumber(value: screenX)) ?? "\(screenX)",
                formatter.string(from: NSNumber(value: screenY)) ?? "\(screenY)"
            )
        } else {
            let width = Int(currentRect.width)
            let height = Int(currentRect.height)
            return (
                formatter.string(from: NSNumber(value: width)) ?? "\(width)",
                formatter.string(from: NSNumber(value: height)) ?? "\(height)"
            )
        }
    }

    /// Draws the grey outline, black crosshair lines, circle ring, and centre dot.
    private func drawCrosshairSymbol(centerX: CGFloat, centerY: CGFloat, halfSize: CGFloat) {
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

    private struct CursorLabelContext {
        let line1: String
        let line2: String
        let str1: NSAttributedString
        let str2: NSAttributedString
        let outlineAttributes: [NSAttributedString.Key: Any]
        let textOffset: CGFloat
        let textHeight: CGFloat
    }

    /// Draws the two coordinate/size label strings with outline and fill passes.
    private func drawCursorLabels(context: CursorLabelContext, centerX: CGFloat, centerY: CGFloat) {
        let textX = centerX + Constants.cursorCircleRadius + 2
        let text1Y = centerY - context.textOffset - context.textHeight
        let text2Y = text1Y - context.textHeight

        NSAttributedString(string: context.line1, attributes: context.outlineAttributes)
            .draw(at: NSPoint(x: textX, y: text1Y))
        NSAttributedString(string: context.line2, attributes: context.outlineAttributes)
            .draw(at: NSPoint(x: textX, y: text2Y))
        context.str1.draw(at: NSPoint(x: textX, y: text1Y))
        context.str2.draw(at: NSPoint(x: textX, y: text2Y))
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
        currentRect = makeRect(from: start, to: current)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint else { return }
        let end = convert(event.locationInWindow, from: nil)
        let selectionRect = makeRect(from: start, to: end)

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

        // .common モードで登録し、スペース遷移アニメーション中もタイマーが発火するようにする
        if window != nil, !isStopped {
            cursorTimer?.invalidate()
            let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, !self.isStopped,
                          let win = self.window as? SelectionOverlayWindow,
                          !win.isDismissed else { return }

                    if !win.isKeyWindow {
                        win.activateAndFocus()
                    }

                    let windowPoint = win.convertPoint(fromScreen: NSEvent.mouseLocation)
                    self.mouseLocation = self.convert(windowPoint, from: nil)
                    self.makeCursorWithLabel().set()
                    self.needsDisplay = true
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            cursorTimer = timer
        }
    }

    override func mouseMoved(with event: NSEvent) {
        mouseLocation = convert(event.locationInWindow, from: nil)
        makeCursorWithLabel().set()
        needsDisplay = true
    }

    func refreshCursor() {
        makeCursorWithLabel().set()
    }

    func stopCursorTimer() {
        isStopped = true
        cursorTimer?.invalidate()
        cursorTimer = nil
    }

    // MARK: - Private Helpers

    private func makeRect(from pointA: NSPoint, to pointB: NSPoint) -> CGRect {
        let minX = min(pointA.x, pointB.x)
        let minY = min(pointA.y, pointB.y)
        let width = abs(pointB.x - pointA.x)
        let height = abs(pointB.y - pointA.y)
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
}
