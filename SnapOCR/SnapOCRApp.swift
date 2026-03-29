//
//  SnapOCRApp.swift
//  SnapOCR
//

import SwiftUI

@main
struct SnapOCRApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                permissionService: appDelegate.permissionService,
                settingsService: appDelegate.settingsService,
                loginItemService: appDelegate.loginItemService,
                historyService: appDelegate.historyService,
                onShowOnboarding: { appDelegate.showOnboarding() },
                onShowHistory: { appDelegate.showHistoryWindow() },
                updater: appDelegate.updateService.updater
            )
        }
    }
}
