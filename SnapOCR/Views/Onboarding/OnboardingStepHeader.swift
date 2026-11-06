//
//  OnboardingStepHeader.swift
//  SnapOCR
//

import SwiftUI

/// オンボーディングの各ステップ共通の見出し（アイコン、タイトル、説明文）。
@MainActor
struct OnboardingStepHeader: View {
    let systemImage: String
    let title: String
    var titleFont: Font = .title2
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(titleFont)
                    .fontWeight(.bold)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
