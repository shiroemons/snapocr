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
    static let badgeFontSize: CGFloat = 11
    static let badgePadding: CGFloat = 4
    static let badgeOffset: CGFloat = 6
    static let badgeAlpha: CGFloat = 0.7
    static let badgeCornerRadius: CGFloat = 3
}

final class SelectionOverlayView: NSView {
    var onSelectionCompleted: ((CGRect) -> Void)?
    var onSelectionCancelled: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: CGRect = .zero

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard !currentRect.isEmpty else {
            // Draw nearly invisible background to ensure mouse event delivery
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

        drawSizeLabel(for: currentRect)
    }

    private func drawSizeLabel(for rect: CGRect) {
        let width = Int(rect.width)
        let height = Int(rect.height)
        let labelText = "\(width) × \(height)"

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: Constants.badgeFontSize, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let attributedString = NSAttributedString(string: labelText, attributes: attributes)
        let textSize = attributedString.size()

        let padding = Constants.badgePadding
        let badgeWidth = textSize.width + padding * 2
        let badgeHeight = textSize.height + padding * 2
        let badgeOffset = Constants.badgeOffset

        var badgeX = rect.maxX - badgeWidth - badgeOffset
        var badgeY = rect.minY - badgeHeight - badgeOffset

        // Keep badge within view bounds
        if badgeX < bounds.minX {
            badgeX = bounds.minX + badgeOffset
        }
        if badgeY < bounds.minY {
            badgeY = rect.minY + badgeOffset
        }

        let badgeRect = CGRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight)

        NSColor.black.withAlphaComponent(Constants.badgeAlpha).setFill()
        let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: Constants.badgeCornerRadius, yRadius: Constants.badgeCornerRadius)
        badgePath.fill()

        let textRect = CGRect(
            x: badgeX + padding,
            y: badgeY + padding,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
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

    // MARK: - Cursor

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.cursorUpdate, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
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
