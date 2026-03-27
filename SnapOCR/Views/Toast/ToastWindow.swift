//
//  ToastWindow.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
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
}

// MARK: - SwiftUI Content View

private struct ToastContentView: View {
    let text: String
    let bundle: Bundle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 16, weight: .medium))

                Text(String(
                    localized: "Copied to Clipboard",
                    bundle: bundle,
                    comment: "Toast notification title when OCR text is copied to clipboard"
                ))
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(text)
                .font(.system(size: 12))
                .lineLimit(Constants.maxTextLines)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
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

    static func show(text: String, bundle: Bundle = .main) {
        current?.dismissImmediately()
        let toast = ToastWindow()
        current = toast
        toast.present(text: text, bundle: bundle)
    }

    // MARK: - Private

    private func present(text: String, bundle: Bundle) {
        let displayText = String(text.prefix(Constants.maxTextLength))
        let contentView = ToastContentView(text: displayText, bundle: bundle)
        let hosting = NSHostingView(rootView: contentView)
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
