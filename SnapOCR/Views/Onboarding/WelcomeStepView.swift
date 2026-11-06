//
//  WelcomeStepView.swift
//  SnapOCR
//

import SwiftUI

/// Step 1: SnapOCR へようこそ
@MainActor
struct WelcomeStepView: View {
    let settingsService: SettingsService

    private var bundle: Bundle { settingsService.localizationBundle }

    var body: some View {
        OnboardingStepHeader(
            systemImage: "text.viewfinder",
            title: String(localized: "SnapOCR", bundle: bundle, comment: "App name shown on the Welcome step"),
            titleFont: .largeTitle,
            description: String(
                // swiftlint:disable:next line_length
                localized: "Capture text from anywhere on your screen.\nPress the hotkey, drag to select a region, and the recognized text is instantly copied to your clipboard.",
                bundle: bundle,
                comment: "Welcome step description explaining the core workflow"
            )
        )
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    WelcomeStepView(settingsService: SettingsService())
        .frame(width: 500, height: 300)
        .padding()
}
#endif
