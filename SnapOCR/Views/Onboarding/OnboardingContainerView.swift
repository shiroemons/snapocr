//
//  OnboardingContainerView.swift
//  SnapOCR
//

import SwiftUI

private enum Constants {
    static let totalSteps = 4
}

/// オンボーディングウィザードのコンテナ。ステップナビゲーションと各ステップ View を管理する。
@MainActor
struct OnboardingContainerView: View {
    let settingsService: SettingsService
    let permissionService: PermissionService
    let onComplete: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    @State private var currentStep = 1

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
                .padding(.top, 24)
                .padding(.bottom, 20)

            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            navigationButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 16)
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...Constants.totalSteps, id: \.self) { step in
                Circle()
                    .fill(step == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                localized: "Step \(currentStep) of \(Constants.totalSteps)",
                bundle: bundle,
                comment: "Accessibility label for the step progress indicator"
            )
        )
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 1:
            WelcomeStepView(settingsService: settingsService)
        case 2:
            PermissionStepView(
                permissionService: permissionService,
                settingsService: settingsService
            )
        case 3:
            HotkeyStepView(settingsService: settingsService)
        case 4:
            CompletionStepView(settingsService: settingsService)
        default:
            EmptyView()
        }
    }

    // MARK: - Navigation Buttons

    @ViewBuilder
    private var navigationButtons: some View {
        switch currentStep {
        case 1:
            HStack {
                Spacer()
                nextButton
            }
        case 2:
            HStack {
                backButton
                Spacer()
                if !permissionService.isScreenCapturePermitted {
                    Button(
                        String(localized: "Skip", bundle: bundle, comment: "Button to skip the current onboarding step")
                    ) {
                        advance()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                nextButton
                    .disabled(!permissionService.isScreenCapturePermitted)
            }
        case 3:
            HStack {
                backButton
                Spacer()
                nextButton
            }
        case 4:
            HStack {
                Spacer()
                Button(
                    String(
                        localized: "Get Started",
                        bundle: bundle,
                        comment: "Button to finish onboarding and start using the app"
                    )
                ) {
                    // × で閉じた場合は未完了のまま次回起動時に再表示するので、完了はここでだけ記録する
                    settingsService.hasCompletedOnboarding = true
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .accessibilityHint(
                    String(
                        localized: "Finish setup and start using SnapOCR",
                        bundle: bundle,
                        comment: "Accessibility hint for the button that completes onboarding"
                    )
                )
            }
        default:
            EmptyView()
        }
    }

    private var nextButton: some View {
        Button(String(localized: "Next", bundle: bundle, comment: "Button to advance to the next onboarding step")) {
            advance()
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
    }

    private var backButton: some View {
        Button(
            String(localized: "Back", bundle: bundle, comment: "Button to go back to the previous onboarding step")
        ) {
            retreat()
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Navigation Helpers

    private func advance() {
        guard currentStep < Constants.totalSteps else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep += 1
        }
    }

    private func retreat() {
        guard currentStep > 1 else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep -= 1
        }
    }
}

#if DEBUG
#Preview {
    OnboardingContainerView(
        settingsService: SettingsService(),
        permissionService: PermissionService()
    ) {
        print("Onboarding complete")
    }
    .frame(width: 500, height: 500)
}
#endif
