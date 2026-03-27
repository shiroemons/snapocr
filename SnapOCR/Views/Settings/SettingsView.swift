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
    let onShowOnboarding: () -> Void
    let onShowHistory: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    var body: some View {
        TabView {
            GeneralSettingsView(
                permissionService: permissionService,
                settingsService: settingsService,
                loginItemService: loginItemService,
                onShowOnboarding: onShowOnboarding
            )
            .tabItem {
                Label(
                    String(localized: "General", bundle: bundle, comment: "General settings tab title"),
                    systemImage: "gearshape"
                )
            }

            OCRSettingsView(settingsService: settingsService)
                .tabItem {
                    Label(
                        String(localized: "OCR", bundle: bundle, comment: "OCR settings tab title"),
                        systemImage: "text.viewfinder"
                    )
                }

            NotificationSettingsView(settingsService: settingsService)
                .tabItem {
                    Label(
                        String(localized: "Notifications", bundle: bundle, comment: "Notifications settings tab title"),
                        systemImage: "bell"
                    )
                }

            HistorySettingsView(settingsService: settingsService, historyService: historyService, onShowHistory: onShowHistory)
                .tabItem {
                    Label(
                        String(localized: "History", bundle: bundle, comment: "History settings tab title"),
                        systemImage: "clock.arrow.circlepath"
                    )
                }

            UpdateSettingsView(settingsService: settingsService)
                .tabItem {
                    Label(
                        String(localized: "Updates", bundle: bundle, comment: "Updates settings tab title"),
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
        }
        .tabViewStyle(.automatic)
        .frame(width: 800, height: 600)
    }
}
