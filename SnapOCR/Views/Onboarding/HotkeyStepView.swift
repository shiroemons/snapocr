//
//  HotkeyStepView.swift
//  SnapOCR
//

import SwiftUI

/// Step 3: ホットキーの設定
@MainActor
struct HotkeyStepView: View {
    let settingsService: SettingsService

    private var bundle: Bundle { settingsService.localizationBundle }

    var body: some View {
        VStack(spacing: 24) {
            OnboardingStepHeader(
                systemImage: "keyboard",
                title: String(localized: "Set Your Capture Hotkey", bundle: bundle, comment: "Hotkey step title"),
                description: String(
                    // swiftlint:disable:next line_length
                    localized: "A global hotkey lets you start a capture from anywhere, even when SnapOCR is in the background. The default shortcut is ⌃⇧O.",
                    bundle: bundle,
                    comment: "Hotkey step description explaining the hotkey feature and default shortcut"
                )
            )

            VStack(spacing: 12) {
                Text(
                    String(
                        localized: "Capture Hotkey",
                        bundle: bundle,
                        comment: "Label for the hotkey recorder in the onboarding hotkey step"
                    )
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

                HotkeyRecorderView(settingsService: settingsService)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            Text(
                String(
                    // swiftlint:disable:next line_length
                    localized: "Click the shortcut field and press a new key combination to change it. Press Escape to cancel.",
                    bundle: bundle,
                    comment: "Hint text explaining how to record a new hotkey"
                )
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    let settingsService = SettingsService()

    HotkeyStepView(settingsService: settingsService)
        .frame(width: 500, height: 400)
        .padding()
}
#endif
