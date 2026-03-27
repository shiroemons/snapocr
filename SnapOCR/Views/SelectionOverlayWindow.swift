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
    nonisolated(unsafe) private var spaceChangeObserver: NSObjectProtocol?
    private(set) var isDismissed = false

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
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
        contentView = overlayView
        disableCursorRects()

        // スペース切り替え時に即座にキーウィンドウを再取得（タイマーを待たず即復帰）
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.isDismissed else { return }
                self.activateAndFocus()
                self.overlayView.refreshCursor()
            }
        }
    }

    func activateAndFocus() {
        NSApp.activate()
        orderFrontRegardless()
        makeKey()
        makeFirstResponder(overlayView)
    }

    /// オーバーレイ終了時のクリーンアップ（オブザーバー解除）
    func cleanup() {
        if let observer = spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            spaceChangeObserver = nil
        }
    }

    deinit {
        if let observer = spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func becomeKey() {
        super.becomeKey()
        // キーウィンドウ復帰時に必ず first responder を再設定（Escape が効かなくなる問題の対策）
        makeFirstResponder(overlayView)
    }

    func show() {
        NSApp.activate()
        makeKeyAndOrderFront(nil)
        makeFirstResponder(overlayView)
        // 初期マウス位置を設定
        let globalMouse = NSEvent.mouseLocation
        let windowPoint = convertPoint(fromScreen: globalMouse)
        overlayView.mouseLocation = overlayView.convert(windowPoint, from: nil)
        overlayView.needsDisplay = true
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
            var observer: NSObjectProtocol?

            nonisolated(unsafe) let resume: (SelectionResult?) -> Void = { result in
                guard !resumed else { return }
                resumed = true
                if let obs = observer { NotificationCenter.default.removeObserver(obs) }
                window.isDismissed = true
                window.overlayView.stopCursorTimer()
                window.cleanup()
                window.ignoresMouseEvents = true
                window.overlayView.onSelectionCompleted = nil
                window.overlayView.onSelectionCancelled = nil
                window.orderOut(nil)
                NSCursor.arrow.set()
                continuation.resume(returning: result)
            }

            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { _ in
                MainActor.assumeIsolated {
                    resume(nil)
                }
            }

            window.overlayView.onSelectionCompleted = { rect in
                resume(SelectionResult(
                    rect: rect,
                    displayID: screenNumber,
                    screenSize: screen.frame.size,
                    scaleFactor: screen.backingScaleFactor
                ))
            }

            window.overlayView.onSelectionCancelled = {
                resume(nil)
            }

            window.show()
        }
    }
}
