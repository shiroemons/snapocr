//
//  NotificationSettingsView.swift
//  SnapOCR
//

import SwiftUI

/// 通知設定タブ。通知センター・完了音・トーストの各通知方法を切り替える。
@MainActor
struct NotificationSettingsView: View {
    let settingsService: SettingsService

    private var bundle: Bundle { settingsService.localizationBundle }
    private let availableSounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk",
        "Glass", "Hero", "Morse", "Ping", "Pop",
        "Purr", "Sosumi", "Submarine", "Tink",
    ]

    var body: some View {
        Form {
            notificationCenterSection
            soundSection
            toastSection
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Notification Center

    private var notificationCenterSection: some View {
        Section {
            Toggle(
                String(
                    localized: "Notification Center",
                    bundle: bundle,
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
                    bundle: bundle,
                    comment: "Notification center description"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        } header: {
            Text(
                String(
                    localized: "Notification Center",
                    bundle: bundle,
                    comment: "Notification center section header in Notification settings"
                )
            )
        }
    }

    // MARK: - Sound

    private var soundSection: some View {
        Section {
            Toggle(
                String(
                    localized: "Completion Sound",
                    bundle: bundle,
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
                        bundle: bundle,
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
                .accessibilityLabel(
                    String(
                        localized: "Completion sound selection",
                        bundle: bundle,
                        comment: "Accessibility label for the sound picker in notification settings"
                    )
                )

                HStack {
                    Spacer()
                    Button(
                        String(
                            localized: "Test Sound",
                            bundle: bundle,
                            comment: "Button to test the selected sound"
                        )
                    ) {
                        NotificationService.playSound(named: settingsService.completionSoundName)
                    }
                    .accessibilityLabel(
                        String(
                            localized: "Preview the selected completion sound",
                            bundle: bundle,
                            comment: "Accessibility label for the button that plays a preview of the selected sound"
                        )
                    )
                }
            }
        } header: {
            Text(
                String(
                    localized: "Sound",
                    bundle: bundle,
                    comment: "Sound section header in Notification settings"
                )
            )
        }
    }

    // MARK: - Toast

    private var toastSection: some View {
        Section {
            Toggle(
                String(
                    localized: "Screen Toast",
                    bundle: bundle,
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
                    bundle: bundle,
                    comment: "Toast description"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        } header: {
            Text(
                String(
                    localized: "Toast",
                    bundle: bundle,
                    comment: "Toast section header in Notification settings"
                )
            )
        }
    }
}
