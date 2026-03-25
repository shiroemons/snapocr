//
//  SettingsView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct SettingsView: View {
    let permissionService: PermissionService
    let settingsService: SettingsService
    let loginItemService: LoginItemService
    let historyService: HistoryService

    var body: some View {
        TabView {
            GeneralSettingsView(
                permissionService: permissionService,
                settingsService: settingsService,
                loginItemService: loginItemService
            )
            .tabItem {
                Label(
                    String(localized: "General", comment: "General settings tab title"),
                    systemImage: "gearshape"
                )
            }

            OCRSettingsView(settingsService: settingsService)
                .tabItem {
                    Label(
                        String(localized: "OCR", comment: "OCR settings tab title"),
                        systemImage: "text.viewfinder"
                    )
                }

            NotificationSettingsView(settingsService: settingsService)
                .tabItem {
                    Label(
                        String(localized: "Notifications", comment: "Notifications settings tab title"),
                        systemImage: "bell"
                    )
                }

            HistorySettingsView(settingsService: settingsService, historyService: historyService)
                .tabItem {
                    Label(
                        String(localized: "History", comment: "History settings tab title"),
                        systemImage: "clock.arrow.circlepath"
                    )
                }

            UpdateSettingsView()
                .tabItem {
                    Label(
                        String(localized: "Updates", comment: "Updates settings tab title"),
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
        }
        .tabViewStyle(.automatic)
        .frame(width: 800, height: 600)
    }
}
