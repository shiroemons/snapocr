//
//  SnapOCRApp.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
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
                historyService: appDelegate.historyService
            )
        }
    }
}
