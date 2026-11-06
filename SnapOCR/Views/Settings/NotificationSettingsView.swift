//
//  NotificationSettingsView.swift
//  SnapOCR
//

import AppKit
import SwiftUI

/// 通知設定タブ。通知センター・完了音・トーストの各通知方法を切り替える。
@MainActor
struct NotificationSettingsView: View {
    @Bindable var settingsService: SettingsService

    @State private var isAuthorizationDenied = false

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
        .task {
            await refreshAuthorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await refreshAuthorizationStatus() }
        }
    }

    private func refreshAuthorizationStatus() async {
        isAuthorizationDenied = await NotificationService.isAuthorizationDenied()
    }

    // MARK: - Notification Center

    private var notificationCenterSection: some View {
        Section(String(
            localized: "Notification Center",
            bundle: bundle,
            comment: "Notification center section header in Notification settings"
        )) {
            Toggle(
                String(
                    localized: "Notification Center",
                    bundle: bundle,
                    comment: "Toggle for macOS notification center"
                ),
                isOn: $settingsService.isNotificationCenterEnabled
            )
            Text(
                String(
                    // swiftlint:disable:next line_length
                    localized: "Show a macOS notification when text is copied. By default, it shows only the character count.",
                    bundle: bundle,
                    comment: "Notification center description"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if settingsService.isNotificationCenterEnabled, isAuthorizationDenied {
                authorizationDeniedRow
            }

            Toggle(
                String(
                    localized: "Show Preview in Notification Body",
                    bundle: bundle,
                    comment: "Toggle for including the beginning of the recognized text in notifications"
                ),
                isOn: $settingsService.isNotificationPreviewEnabled
            )
            .disabled(!settingsService.isNotificationCenterEnabled)
            Text(
                String(
                    // swiftlint:disable:next line_length
                    localized: "Includes the beginning of the recognized text in the notification. It can be seen during screen sharing and in the notification history.",
                    bundle: bundle,
                    comment: "Description of the notification preview toggle"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var authorizationDeniedRow: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(String(
                localized: "Notifications for SnapOCR are turned off in System Settings.",
                bundle: bundle,
                comment: "Shown when the OS denies notifications for the app"
            ))
            Spacer()
            Button(String(
                localized: "Open System Settings",
                bundle: bundle,
                comment: "Button to open the notification page in System Settings"
            )) {
                openNotificationSettings()
            }
        }
    }

    private func openNotificationSettings() {
        let settingsURLString = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        guard let url = URL(string: settingsURLString) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Sound

    private var soundSection: some View {
        Section(String(localized: "Sound", bundle: bundle, comment: "Sound section header in Notification settings")) {
            Toggle(
                String(localized: "Completion Sound", bundle: bundle, comment: "Toggle for completion sound"),
                isOn: $settingsService.isCompletionSoundEnabled
            )

            if settingsService.isCompletionSoundEnabled {
                Picker(
                    String(localized: "Sound", bundle: bundle, comment: "Sound picker label"),
                    selection: $settingsService.completionSoundName
                ) {
                    ForEach(availableSounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .accessibilityHint(String(
                    localized: "Completion sound selection",
                    bundle: bundle,
                    comment: "Accessibility hint for the sound picker in notification settings"
                ))

                HStack {
                    Spacer()
                    Button(
                        String(localized: "Test Sound", bundle: bundle, comment: "Button to test the selected sound")
                    ) {
                        NotificationService.playSound(named: settingsService.completionSoundName)
                    }
                    .accessibilityHint(String(
                        localized: "Preview the selected completion sound",
                        bundle: bundle,
                        comment: "Accessibility hint for the button that plays a preview of the selected sound"
                    ))
                }
            }
        }
    }

    // MARK: - Toast

    private var toastSection: some View {
        Section(String(localized: "Toast", bundle: bundle, comment: "Toast section header in Notification settings")) {
            Toggle(
                String(localized: "Screen Toast", bundle: bundle, comment: "Toggle for screen toast notification"),
                isOn: $settingsService.isToastEnabled
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
        }
    }
}
