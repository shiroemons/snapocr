//
//  CompletionStepView.swift
//  SnapOCR
//

import SwiftUI

/// Step 4: セットアップ完了ガイド
@MainActor
struct CompletionStepView: View {
    let settingsService: SettingsService

    private var bundle: Bundle { settingsService.localizationBundle }

    private struct UsageStep: Identifiable {
        let id: Int
        let symbol: String
        let title: String
        let description: String
    }

    private var hotkeyDisplayString: String {
        KeyCodeMapping.displayString(
            keyCode: settingsService.hotkeyKeyCode,
            modifiers: settingsService.hotkeyModifiers,
            bundle: bundle
        )
    }

    private var allSteps: [UsageStep] {
        [
            UsageStep(
                id: 1,
                symbol: "keyboard",
                title: String(localized: "Press the hotkey", bundle: bundle, comment: "Usage step 1 title"),
                description: String(
                    localized: "Press \(hotkeyDisplayString) (or your custom shortcut) to activate capture mode.",
                    bundle: bundle,
                    comment: "Usage step 1 description"
                )
            ),
            UsageStep(
                id: 2,
                symbol: "rectangle.dashed",
                title: String(localized: "Select a region", bundle: bundle, comment: "Usage step 2 title"),
                description: String(
                    localized: "Drag to draw a selection around the text you want to recognize.",
                    bundle: bundle,
                    comment: "Usage step 2 description"
                )
            ),
            UsageStep(
                id: 3,
                symbol: "doc.on.clipboard",
                title: String(localized: "Text is copied", bundle: bundle, comment: "Usage step 3 title"),
                description: String(
                    localized: "The recognized text is instantly copied to your clipboard and ready to paste.",
                    bundle: bundle,
                    comment: "Usage step 3 description"
                )
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(Color.green)
                    .accessibilityHidden(true)

                Text(String(localized: "Setup Complete!", bundle: bundle, comment: "Completion step headline"))
                    .font(.title2)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(allSteps) { step in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: step.symbol)
                            .frame(width: 28, height: 28)
                            .font(.system(size: 20))
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(step.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    CompletionStepView(settingsService: SettingsService())
        .frame(width: 500, height: 340)
        .padding()
}
#endif
