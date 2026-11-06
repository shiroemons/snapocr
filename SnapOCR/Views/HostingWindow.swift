//
//  HostingWindow.swift
//  SnapOCR
//

import AppKit
import Observation
import SwiftUI

enum HostingWindow {
    /// SwiftUI ビューを載せたウィンドウを作成し、前面に表示する。
    /// 呼び出し側は返されたウィンドウを保持する（`isReleasedWhenClosed` は false）。
    static func present(
        rootView: some View,
        size: CGSize,
        styleMask: NSWindow.StyleMask,
        title: String,
        delegate: any NSWindowDelegate
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: rootView)
        window.center()
        window.delegate = delegate
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        return window
    }

    /// 開いたまま言語を切り替えてもタイトルが追従するようにする。
    /// 返された Task はウィンドウを閉じるときに cancel する。
    static func trackLocalizedTitle(
        of window: NSWindow,
        settings: SettingsService,
        title: @escaping () -> String
    ) -> Task<Void, Never> {
        Task { [weak window] in
            for await _ in Observations({ settings.appLanguage }) {
                window?.title = title()
            }
        }
    }
}
