//
//  SelectionOverlayWindow.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import AppKit

final class SelectionOverlayWindow: NSWindow {
    private(set) var overlayView: SelectionOverlayView

    init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.frame

        overlayView = SelectionOverlayView(frame: CGRect(origin: .zero, size: screenFrame.size))

        super.init(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false
        contentView = overlayView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func show() {
        makeKeyAndOrderFront(nil)
        overlayView.window?.makeFirstResponder(overlayView)
    }
}

// MARK: - Async Region Selection

extension SelectionOverlayWindow {
    @MainActor
    static func selectRegion() async -> CGRect? {
        await withCheckedContinuation { continuation in
            let window = SelectionOverlayWindow()
            var resumed = false

            window.overlayView.onSelectionCompleted = { rect in
                guard !resumed else { return }
                resumed = true
                window.orderOut(nil)
                continuation.resume(returning: rect)
            }

            window.overlayView.onSelectionCancelled = {
                guard !resumed else { return }
                resumed = true
                window.orderOut(nil)
                continuation.resume(returning: nil)
            }

            window.show()
        }
    }
}
