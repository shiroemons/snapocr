//
//  NotificationSettingsView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

/// 通知設定タブ。通知センター・完了音・トーストの各通知方法を切り替える。
@MainActor
struct NotificationSettingsView: View {
    let settingsService: SettingsService

    private let availableSounds = ["Tink", "Pop", "Glass", "Purr", "Ping"]

    var body: some View {
        Form {
            notificationCenterSection
            soundSection
            toastSection
        }
        .formStyle(.grouped)
    }

    // MARK: - Notification Center

    private var notificationCenterSection: some View {
        Section {
            Toggle(
                String(
                    localized: "Notification Center",
                    comment: "Toggle for macOS notification center"
                ),
                isOn: Binding(
                    get: { settingsService.isNotificationCenterEnabled },
                    set: { settingsService.isNotificationCenterEnabled = $0 }
                )
            )
            Text(
                String(
                    localized: "Show a macOS notification with a preview of the recognized text.",
                    comment: "Notification center description"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sound

    private var soundSection: some View {
        Section {
            Toggle(
                String(
                    localized: "Completion Sound",
                    comment: "Toggle for completion sound"
                ),
                isOn: Binding(
                    get: { settingsService.isCompletionSoundEnabled },
                    set: { settingsService.isCompletionSoundEnabled = $0 }
                )
            )

            if settingsService.isCompletionSoundEnabled {
                Picker(
                    String(
                        localized: "Sound",
                        comment: "Sound picker label"
                    ),
                    selection: Binding(
                        get: { settingsService.completionSoundName },
                        set: { settingsService.completionSoundName = $0 }
                    )
                ) {
                    ForEach(availableSounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }

                Button(
                    String(
                        localized: "Test Sound",
                        comment: "Button to test the selected sound"
                    )
                ) {
                    NotificationService.playSound(named: settingsService.completionSoundName)
                }
            }
        }
    }

    // MARK: - Toast

    private var toastSection: some View {
        Section {
            Toggle(
                String(
                    localized: "Screen Toast",
                    comment: "Toggle for screen toast notification"
                ),
                isOn: Binding(
                    get: { settingsService.isToastEnabled },
                    set: { settingsService.isToastEnabled = $0 }
                )
            )
            Text(
                String(
                    localized: "Show a floating notification at the top of the screen that auto-dismisses.",
                    comment: "Toast description"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
