//
//  AppDelegate.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import AppKit
import os
import SwiftData
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "AppDelegate")
    private var statusItem: NSStatusItem?
    let permissionService = PermissionService()
    let settingsService = SettingsService()
    let loginItemService = LoginItemService()
    private(set) lazy var historyService: HistoryService = HistoryService(
        modelContainer: Self.makeModelContainer(logger: Self.logger)
    )

    private static func makeModelContainer(logger: Logger) -> ModelContainer {
        do {
            return try ModelContainer(for: CaptureRecord.self)
        } catch {
            logger.error("ModelContainer failed, falling back to in-memory store: \(error.localizedDescription, privacy: .public)")
        }
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: CaptureRecord.self, configurations: config)
        } catch {
            logger.critical("In-memory ModelContainer creation failed: \(error.localizedDescription, privacy: .public)")
            // This path is not reachable in practice: an in-memory store with no
            // migration or file I/O cannot fail. If it somehow does, the process
            // cannot run without a persistence layer, so we surface a clear message.
            preconditionFailure("In-memory ModelContainer creation failed: \(error.localizedDescription)")
        }
    }
    private lazy var viewModel: AppViewModel = AppViewModel(
        permissionService: permissionService,
        settingsService: settingsService,
        historyService: historyService
    )
    private var isTrackingActive = true
    private var panelItem: NSMenuItem?
    private var hostingView: NSHostingView<MenuBarPanelView>?
    private var onboardingWindow: OnboardingWindow?
    private var historyWindow: HistoryWindow?
    private lazy var warningBadgedIcon: NSImage? = makeWarningBadgedIcon()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationService.requestPermission()
        setupMenuBar()
        viewModel.setup()
        updateStatusItemIcon()
        applyAppearance()
        trackAppearanceChanges()
        trackLanguageChanges()
        trackPermissionChanges()

        if settingsService.shouldShowOnboarding {
            showOnboarding()
        }
    }

    // MARK: - Onboarding Window

    func showOnboarding() {
        if let existing = onboardingWindow, existing.isVisible {
            existing.bringToFront()
            return
        }
        let window = OnboardingWindow(settingsService: settingsService)
        window.onDismiss = { [weak self] in
            self?.onboardingWindow = nil
        }
        window.present(permissionService: permissionService)
        onboardingWindow = window
    }

    func applicationWillTerminate(_ notification: Notification) {
        isTrackingActive = false
        permissionService.stopMonitoring()
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
            historyService: historyService,
            onCapture: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
                self?.viewModel.startCapture()
            },
            onDismissMenu: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
            },
            onShowHistory: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
                self?.showHistoryWindow()
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

    // MARK: - History Window

    func showHistoryWindow() {
        if let existing = historyWindow {
            existing.bringToFront()
            return
        }
        let window = HistoryWindow(settingsService: settingsService)
        window.onDismiss = { [weak self] in
            self?.historyWindow = nil
        }
        window.present(historyService: historyService)
        historyWindow = window
    }

    // MARK: - Status Item Icon

    private func updateStatusItemIcon() {
        guard let button = statusItem?.button else { return }

        if permissionService.isScreenCapturePermitted {
            button.image = NSImage(
                systemSymbolName: "text.viewfinder",
                accessibilityDescription: String(localized: "SnapOCR", bundle: settingsService.localizationBundle, comment: "Accessibility description for menu bar icon")
            )
        } else {
            button.image = warningBadgedIcon
        }
    }

    private func makeWarningBadgedIcon() -> NSImage? {
        guard let base = NSImage(
            systemSymbolName: "text.viewfinder",
            accessibilityDescription: String(localized: "SnapOCR", bundle: settingsService.localizationBundle, comment: "Accessibility description for menu bar icon")
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

    // MARK: - Appearance

    private func applyAppearance() {
        NSApplication.shared.appearance = switch settingsService.appearanceMode {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    private func trackAppearanceChanges() {
        withObservationTracking {
            _ = settingsService.appearanceMode
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.isTrackingActive else { return }
                self.applyAppearance()
                self.trackAppearanceChanges()
            }
        }
    }

    private func trackLanguageChanges() {
        withObservationTracking {
            _ = settingsService.appLanguage
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.isTrackingActive else { return }
                self.updateStatusItemIcon()
                self.trackLanguageChanges()
            }
        }
    }

    // MARK: - Permission Observation

    private func trackPermissionChanges() {
        withObservationTracking {
            _ = permissionService.isScreenCapturePermitted
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.isTrackingActive else { return }
                self.updateStatusItemIcon()
                self.trackPermissionChanges()
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
