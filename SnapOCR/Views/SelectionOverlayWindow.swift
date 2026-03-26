//
//  SelectionOverlayWindow.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import AppKit

struct SelectionResult: Sendable {
    let rect: CGRect
    let displayID: CGDirectDisplayID
    let screenSize: CGSize
    let scaleFactor: CGFloat
}

final class SelectionOverlayWindow: NSWindow {
    private(set) var overlayView: SelectionOverlayView

    init(screen: NSScreen) {
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
        NSApp.activate()
        makeKeyAndOrderFront(nil)
        overlayView.window?.makeFirstResponder(overlayView)
    }
}

// MARK: - Async Region Selection

extension SelectionOverlayWindow {
    @MainActor
    static func selectRegion() async -> SelectionResult? {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        else { return nil }

        guard let screenNumber = screen.deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? CGDirectDisplayID else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let window = SelectionOverlayWindow(screen: screen)
            var resumed = false

            let resume: (SelectionResult?) -> Void = { result in
                guard !resumed else { return }
                resumed = true
                window.orderOut(nil)
                continuation.resume(returning: result)
            }

            // Guard against system-initiated window close (e.g., screen lock, Exposé) that
            // bypasses the selection callbacks, which would otherwise leave the continuation
            // permanently suspended.
            var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { _ in
                if let obs = observer { NotificationCenter.default.removeObserver(obs) }
                resume(nil)
            }

            window.overlayView.onSelectionCompleted = { rect in
                if let obs = observer { NotificationCenter.default.removeObserver(obs) }
                resume(SelectionResult(
                    rect: rect,
                    displayID: screenNumber,
                    screenSize: screen.frame.size,
                    scaleFactor: screen.backingScaleFactor
                ))
            }

            window.overlayView.onSelectionCancelled = {
                if let obs = observer { NotificationCenter.default.removeObserver(obs) }
                resume(nil)
            }

            window.show()
        }
    }
}
