//
//  ToastWindow.swift
//  SnapOCR
//

import AppKit
import SwiftUI

private enum Constants {
    static let windowWidth: CGFloat = 360
    static let maxWindowHeight: CGFloat = 200
    static let maxTextLines: Int = 5
    static let maxTextLength: Int = 500
    static let margin: CGFloat = 20
    static let dismissDelay: Duration = .seconds(2.5)
    static let errorDismissDelay: Duration = .seconds(4)
}

// MARK: - SwiftUI Content View

private struct ToastContentView: View {
    let systemImage: String
    let tint: Color
    let title: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .font(.system(size: 16, weight: .medium))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let detail {
                Text(detail)
                    .font(.system(size: 12))
                    .lineLimit(Constants.maxTextLines)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: Constants.windowWidth)
        .frame(maxHeight: Constants.maxWindowHeight)
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

    static func show(text: String, bundle: Bundle) {
        let title = String(
            localized: "Copied to Clipboard",
            bundle: bundle,
            comment: "Toast notification title when OCR text is copied to clipboard"
        )
        present(
            ToastContentView(
                systemImage: "checkmark.circle.fill",
                tint: .green,
                title: title,
                detail: String(text.prefix(Constants.maxTextLength))
            ),
            dismissDelay: Constants.dismissDelay
        )
        AccessibilityNotification.Announcement(title).post()
    }

    /// 失敗をユーザーに伝える。トーストの設定に関係なく表示する。
    static func showError(message: String) {
        present(
            ToastContentView(
                systemImage: "exclamationmark.triangle.fill",
                tint: .orange,
                title: message,
                detail: nil
            ),
            dismissDelay: Constants.errorDismissDelay
        )
        AccessibilityNotification.Announcement(message).post()
    }

    // MARK: - Private

    private static func present(_ content: ToastContentView, dismissDelay: Duration) {
        current?.dismissImmediately()
        let toast = ToastWindow()
        current = toast
        toast.show(content, dismissDelay: dismissDelay)
    }

    private func show(_ content: ToastContentView, dismissDelay: Duration) {
        let hosting = NSHostingView(rootView: content)
        let fittedSize = hosting.fittingSize
        let clampedSize = CGSize(width: fittedSize.width, height: min(fittedSize.height, Constants.maxWindowHeight))
        hosting.frame = CGRect(origin: .zero, size: clampedSize)

        let win = NSWindow(
            contentRect: CGRect(origin: .zero, size: clampedSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isReleasedWhenClosed = false
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = true
        win.level = .floating
        // フルスクリーンの Space でも結果やエラーが見えるようにする
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        win.ignoresMouseEvents = true
        win.contentView = hosting

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let originX = screenFrame.maxX - clampedSize.width - Constants.margin
            let originY = screenFrame.maxY - clampedSize.height - Constants.margin
            win.setFrameOrigin(NSPoint(x: originX, y: originY))
        }

        win.alphaValue = 1
        win.orderFrontRegardless()
        self.window = win

        scheduleDismiss(after: dismissDelay)
    }

    private func scheduleDismiss(after delay: Duration) {
        dismissTask = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
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
        } completionHandler: { [weak self, weak win] in
            // Task is intentionally not stored: it performs only trivial cleanup
            // (close window, nil two weak references) and is self-cleaning.
            Task { @MainActor in
                win?.close()
                self?.window = nil
                if Self.current === self {
                    Self.current = nil
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
