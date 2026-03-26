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

        let formatter = Self.numberFormatter
        let line1: String
        let line2: String
        if currentRect.isEmpty {
            let screenX = Int(mouseLocation.x)
            let screenY = Int(bounds.height - mouseLocation.y)
            line1 = formatter.string(from: NSNumber(value: screenX)) ?? "\(screenX)"
            line2 = formatter.string(from: NSNumber(value: screenY)) ?? "\(screenY)"
        } else {
            let width = Int(currentRect.width)
            let height = Int(currentRect.height)
            line1 = formatter.string(from: NSNumber(value: width)) ?? "\(width)"
            line2 = formatter.string(from: NSNumber(value: height)) ?? "\(height)"
        }

        let font = NSFont.monospacedDigitSystemFont(ofSize: Constants.labelFontSize, weight: .bold)
        let outlineAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.white,
            .strokeWidth: NSNumber(value: -4.0)
        ]
        let fillAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]

        let str1 = NSAttributedString(string: line1, attributes: fillAttributes)
        let str2 = NSAttributedString(string: line2, attributes: fillAttributes)
        let textHeight = str1.size().height
        let maxTextWidth = max(str1.size().width, str2.size().width)

        let crossSize = Constants.cursorSize
        let halfCross = crossSize / 2
        let textOffset: CGFloat = 2
        let totalTextHeight = textHeight * 2
        let imageWidth = crossSize + textOffset + maxTextWidth + 4
        let imageHeight = crossSize + textOffset + totalTextHeight

        let crossCenterX = halfCross
        let crossCenterY = imageHeight - halfCross

        let image = NSImage(size: NSSize(width: imageWidth, height: imageHeight))
        image.lockFocus()

        let inset = Constants.cursorLineInset
        let r = Constants.cursorCircleRadius

        // グレーの枠
        NSColor.gray.withAlphaComponent(0.5).setStroke()
        let outlinePath = NSBezierPath()
        outlinePath.lineWidth = Constants.cursorOutlineWidth
        outlinePath.lineCapStyle = .round
        outlinePath.move(to: NSPoint(x: crossCenterX, y: crossCenterY - halfCross))
        outlinePath.line(to: NSPoint(x: crossCenterX, y: crossCenterY + halfCross))
        outlinePath.move(to: NSPoint(x: crossCenterX - halfCross, y: crossCenterY))
        outlinePath.line(to: NSPoint(x: crossCenterX + halfCross, y: crossCenterY))
        outlinePath.stroke()

        // 黒い十字線
        NSColor.black.setStroke()
        let crossPath = NSBezierPath()
        crossPath.lineWidth = Constants.cursorLineWidth
        crossPath.move(to: NSPoint(x: crossCenterX, y: crossCenterY - halfCross + inset))
        crossPath.line(to: NSPoint(x: crossCenterX, y: crossCenterY + halfCross - inset))
        crossPath.move(to: NSPoint(x: crossCenterX - halfCross + inset, y: crossCenterY))
        crossPath.line(to: NSPoint(x: crossCenterX + halfCross - inset, y: crossCenterY))
        crossPath.stroke()

        // グレーの中央円リング
        NSColor.gray.withAlphaComponent(0.5).setStroke()
        let circlePath = NSBezierPath(ovalIn: NSRect(
            x: crossCenterX - r, y: crossCenterY - r, width: r * 2, height: r * 2
        ))
        circlePath.lineWidth = Constants.cursorLineWidth
        circlePath.stroke()

        // 中心の白いドット
        NSColor.white.setFill()
        let dr = Constants.cursorDotRadius
        NSBezierPath(ovalIn: NSRect(
            x: crossCenterX - dr, y: crossCenterY - dr, width: dr * 2, height: dr * 2
        )).fill()

        // テキスト描画
        let textX = crossCenterX + r + 2
        let text1Y = crossCenterY - textOffset - textHeight
        let text2Y = text1Y - textHeight

        NSAttributedString(string: line1, attributes: outlineAttributes).draw(at: NSPoint(x: textX, y: text1Y))
        NSAttributedString(string: line2, attributes: outlineAttributes).draw(at: NSPoint(x: textX, y: text2Y))
        str1.draw(at: NSPoint(x: textX, y: text1Y))
        str2.draw(at: NSPoint(x: textX, y: text2Y))

        image.unlockFocus()

        cachedMouseLocation = mouseLocation
        cachedCurrentRect = currentRect
        let cursor = NSCursor(image: image, hotSpot: NSPoint(x: crossCenterX, y: imageHeight - crossCenterY))
        cachedCursor = cursor
        return cursor
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

        if selectionRect.width > Constants.minimumSelectionSize && selectionRect.height > Constants.minimumSelectionSize {
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
