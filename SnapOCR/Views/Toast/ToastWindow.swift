//
//  ToastWindow.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import AppKit
import SwiftUI

private enum Constants {
    static let windowWidth: CGFloat = 300
    static let windowHeight: CGFloat = 50
    static let margin: CGFloat = 20
    static let dismissDelay: Duration = .seconds(2.5)
    static let maxTextLength: Int = 50
}

// MARK: - SwiftUI Content View

private struct ToastContentView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 16, weight: .medium))

            Text(text)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: Constants.windowWidth, height: Constants.windowHeight)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Toast Window

/// トースト通知ウィンドウの管理クラス。
/// OCR完了時などに画面右上へ一時的なトースト通知を表示する。
@MainActor
final class ToastWindow {
    private static var current: ToastWindow?

    private var window: NSWindow?
    private var dismissTask: Task<Void, Never>?

    // MARK: - Public API

    static func show(text: String) {
        current?.dismissImmediately()
        let toast = ToastWindow()
        current = toast
        toast.present(text: text)
    }

    // MARK: - Private

    private func present(text: String) {
        let preview = String(text.prefix(Constants.maxTextLength))
        let contentView = ToastContentView(text: preview)
        let hosting = NSHostingView(rootView: contentView)
        hosting.frame = CGRect(
            x: 0,
            y: 0,
            width: Constants.windowWidth,
            height: Constants.windowHeight
        )

        let win = NSWindow(
            contentRect: CGRect(
                x: 0,
                y: 0,
                width: Constants.windowWidth,
                height: Constants.windowHeight
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isReleasedWhenClosed = false
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = true
        win.level = .floating
        win.ignoresMouseEvents = true
        win.contentView = hosting

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let originX = screenFrame.maxX - Constants.windowWidth - Constants.margin
            let originY = screenFrame.maxY - Constants.windowHeight - Constants.margin
            win.setFrameOrigin(NSPoint(x: originX, y: originY))
        }

        win.alphaValue = 1
        win.orderFrontRegardless()
        self.window = win

        scheduleDismiss()
    }

    private func scheduleDismiss() {
        dismissTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Constants.dismissDelay)
            } catch {
                return
            }
            self?.fadeOutAndClose()
        }
    }

    private func fadeOutAndClose() {
        guard let win = window else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            win.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor [weak self] in
                win.close()
                self?.window = nil
                if ToastWindow.current === self {
                    ToastWindow.current = nil
                }
            }
        }
    }

    private func dismissImmediately() {
        dismissTask?.cancel()
        dismissTask = nil
        window?.close()
        window = nil
    }
}
