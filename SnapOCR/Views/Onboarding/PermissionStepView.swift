//
//  PermissionStepView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

/// Step 2: 画面収録の権限設定
@MainActor
struct PermissionStepView: View {
    let permissionService: PermissionService
    let settingsService: SettingsService
    @Binding var canProceed: Bool

    private var bundle: Bundle { settingsService.localizationBundle }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(
                    String(
                        localized: "Screen Recording Permission",
                        bundle: bundle,
                        comment: "Permission step title"
                    )
                )
                .font(.title2)
                .fontWeight(.bold)

                Text(
                    String(
                        // swiftlint:disable:next line_length
                        localized: "SnapOCR needs permission to capture your screen in order to recognize text. Your screen contents are processed entirely on-device and never sent anywhere.",
                        bundle: bundle,
                        comment: "Permission step description explaining why screen recording access is required"
                    )
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Image(systemName: permissionService.isScreenCapturePermitted
                      ? "checkmark.circle.fill"
                      : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(permissionService.isScreenCapturePermitted ? .green : .orange)
                    .accessibilityHidden(true)

                Text(
                    permissionService.isScreenCapturePermitted
                        ? String(
                            localized: "Permission granted",
                            bundle: bundle,
                            comment: "Screen recording permission is granted"
                        )
                        : String(
                            localized: "Permission not yet granted",
                            bundle: bundle,
                            comment: "Screen recording permission has not been granted yet"
                        )
                )
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(permissionService.isScreenCapturePermitted ? .green : .orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        permissionService.isScreenCapturePermitted
                            ? Color.green.opacity(0.1)
                            : Color.orange.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                permissionService.isScreenCapturePermitted
                                    ? Color.green.opacity(0.4)
                                    : Color.orange.opacity(0.4),
                                lineWidth: 1
                            )
                    )
                    .accessibilityHidden(true)
            )

            if !permissionService.isScreenCapturePermitted {
                Button {
                    permissionService.openSystemSettings()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gear")
                            .accessibilityHidden(true)
                        Text(
                            String(
                                localized: "Open System Settings",
                                bundle: bundle,
                                comment: "Button to open System Settings for granting screen recording permission"
                            )
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel(
                    String(
                        localized: "Open System Settings to grant screen recording permission",
                        bundle: bundle,
                        comment: "Accessibility label for the button that opens System Settings during onboarding"
                    )
                )
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .onAppear {
            permissionService.startMonitoring()
            canProceed = permissionService.isScreenCapturePermitted
        }
        .onDisappear {
            permissionService.stopMonitoring()
        }
        .onChange(of: permissionService.isScreenCapturePermitted) { _, newValue in
            canProceed = newValue
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var canProceed = false
    let permissionService = PermissionService()

    PermissionStepView(
        permissionService: permissionService,
        settingsService: SettingsService(),
        canProceed: $canProceed
    )
        .frame(width: 500, height: 380)
        .padding()
}
#endif
