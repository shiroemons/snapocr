//
//  AppDelegate.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    let permissionService = PermissionService()
    let settingsService = SettingsService()
    let loginItemService = LoginItemService()
    private lazy var viewModel = AppViewModel(
        permissionService: permissionService,
        settingsService: settingsService
    )
    private var panelItem: NSMenuItem?
    private var hostingView: NSHostingView<MenuBarPanelView>?
    private lazy var warningBadgedIcon: NSImage? = makeWarningBadgedIcon()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        viewModel.setup()
        updateStatusItemIcon()
        trackPermissionChanges()

        if settingsService.shouldShowOnboarding {
            OnboardingWindow.show(
                settingsService: settingsService,
                permissionService: permissionService
            )
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.teardown()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        let menu = NSMenu()
        menu.delegate = self

        let item = NSMenuItem()
        let panelView = MenuBarPanelView(
            permissionService: permissionService,
            settingsService: settingsService,
            onCapture: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
                self?.viewModel.startCapture()
            },
            onOpenSettings: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        let view = NSHostingView(rootView: panelView)
        view.frame = CGRect(
            x: 0,
            y: 0,
            width: 320,
            height: view.fittingSize.height
        )
        item.view = view
        menu.addItem(item)

        panelItem = item
        hostingView = view
        statusItem?.menu = menu
    }

    // MARK: - Status Item Icon

    private func updateStatusItemIcon() {
        guard let button = statusItem?.button else { return }

        if permissionService.isScreenCapturePermitted {
            button.image = NSImage(
                systemSymbolName: "text.viewfinder",
                accessibilityDescription: String(localized: "SnapOCR")
            )
        } else {
            button.image = warningBadgedIcon
        }
    }

    private func makeWarningBadgedIcon() -> NSImage? {
        guard let base = NSImage(
            systemSymbolName: "text.viewfinder",
            accessibilityDescription: String(localized: "SnapOCR")
        ) else { return nil }

        let size = base.size
        let composited = NSImage(size: size, flipped: false) { rect in
            base.draw(in: rect)

            let dotDiameter: CGFloat = 7
            let dotRect = CGRect(
                x: rect.maxX - dotDiameter,
                y: rect.minY,
                width: dotDiameter,
                height: dotDiameter
            )
            NSColor.systemOrange.setFill()
            let dotPath = NSBezierPath(ovalIn: dotRect)
            dotPath.fill()

            return true
        }
        composited.isTemplate = false
        return composited
    }

    // MARK: - Permission Observation

    private func trackPermissionChanges() {
        withObservationTracking {
            _ = permissionService.isScreenCapturePermitted
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.updateStatusItemIcon()
                self?.trackPermissionChanges()
            }
        }
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        permissionService.checkPermission()
        updateStatusItemIcon()

        if let hostingView, let panelItem {
            let height = hostingView.fittingSize.height
            hostingView.frame = CGRect(x: 0, y: 0, width: 320, height: height)
            panelItem.view = hostingView
        }
    }
}
