//
//  SelectionOverlayWindow.swift
//  SnapOCR
//

import AppKit

struct SelectionResult: Sendable {
    let rect: CGRect
    let displayID: CGDirectDisplayID
    let screenSize: CGSize
    let scaleFactor: CGFloat
}

final class SelectionOverlayWindow: NSWindow {
    let overlayView: SelectionOverlayView
    private var spaceChangeObserver: NSObjectProtocol?
    private var isDismissed = false

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
                // オブザーバーの解除前にキューへ積まれた通知で、閉じたウィンドウを前面へ戻さない
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

    /// コールバックを nil にして continuation の二重 resume を防ぐ。
    /// selectRegion() の循環参照もここで解けるので、ウィンドウが解放される前に必ず呼ばれ、deinit での解除は要らない
    func dismiss() {
        isDismissed = true
        overlayView.onSelectionCompleted = nil
        overlayView.onSelectionCancelled = nil
        overlayView.stopCursorTimer()
        if let observer = spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            spaceChangeObserver = nil
        }
        ignoresMouseEvents = true
        orderOut(nil)
        NSCursor.arrow.set()
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
    }
}

// MARK: - Async Region Selection

extension SelectionOverlayWindow {
    @MainActor
    static func selectRegion() async -> SelectionResult? {
        let mouseLocation = NSEvent.mouseLocation
        // CGRect.contains は上端の maxY を含まないが、AppKit のマウス座標は画面の上端で maxY になる
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
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

            // このウィンドウを保持するのは下のコールバックだけなので、選択が終わるまで生存させるために強参照でキャプチャする。
            // 循環参照は dismiss() がコールバックを nil にして解く
            window.overlayView.onSelectionCompleted = { rect in
                window.dismiss()
                continuation.resume(returning: SelectionResult(
                    rect: rect,
                    displayID: screenNumber,
                    screenSize: screen.frame.size,
                    scaleFactor: screen.backingScaleFactor
                ))
            }

            window.overlayView.onSelectionCancelled = {
                window.dismiss()
                continuation.resume(returning: nil)
            }

            window.show()
        }
    }
}
