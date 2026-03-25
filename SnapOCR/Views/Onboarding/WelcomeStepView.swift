//
//  WelcomeStepView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

/// Step 1: SnapOCR へようこそ
@MainActor
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.viewfinder")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(String(localized: "SnapOCR", comment: "App name shown on the Welcome step"))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(
                    String(
                        localized: "Capture text from anywhere on your screen.\nPress the hotkey, drag to select a region, and the recognized text is instantly copied to your clipboard.",
                        comment: "Welcome step description explaining the core workflow"
                    )
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    WelcomeStepView()
        .frame(width: 500, height: 300)
        .padding()
}
#endif
