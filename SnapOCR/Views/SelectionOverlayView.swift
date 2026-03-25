//
//  SelectionOverlayView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import AppKit
import Carbon.HIToolbox

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
            NSColor.black.withAlphaComponent(0.01).setFill()
            NSBezierPath.fill(bounds)
            return
        }

        let overlayPath = NSBezierPath()
        overlayPath.windingRule = .evenOdd
        overlayPath.append(NSBezierPath(rect: bounds))
        overlayPath.append(NSBezierPath(rect: currentRect))
        NSColor.black.withAlphaComponent(0.3).setFill()
        overlayPath.fill()

        NSColor.white.setStroke()
        let borderPath = NSBezierPath(rect: currentRect)
        borderPath.lineWidth = 1.0
        borderPath.stroke()

        drawSizeLabel(for: currentRect)
    }

    private func drawSizeLabel(for rect: CGRect) {
        let width = Int(rect.width)
        let height = Int(rect.height)
        let labelText = "\(width) × \(height)"

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let attributedString = NSAttributedString(string: labelText, attributes: attributes)
        let textSize = attributedString.size()

        let padding: CGFloat = 4
        let badgeWidth = textSize.width + padding * 2
        let badgeHeight = textSize.height + padding * 2
        let badgeOffset: CGFloat = 6

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

        NSColor.black.withAlphaComponent(0.7).setFill()
        let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 3, yRadius: 3)
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

        if selectionRect.width > 2 && selectionRect.height > 2 {
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
