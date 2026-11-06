//
//  PermissionStepView.swift
//  SnapOCR
//

import SwiftUI

/// Step 2: 画面収録の権限設定
@MainActor
struct PermissionStepView: View {
    let permissionService: PermissionService
    let settingsService: SettingsService

    private var bundle: Bundle { settingsService.localizationBundle }
    private var isGranted: Bool { permissionService.isScreenCapturePermitted }
    private var statusColor: Color { isGranted ? .green : .orange }

    var body: some View {
        VStack(spacing: 24) {
            OnboardingStepHeader(
                systemImage: "lock.shield",
                title: String(
                    localized: "Screen Recording Permission",
                    bundle: bundle,
                    comment: "Permission step title"
                ),
                description: String(
                    // swiftlint:disable:next line_length
                    localized: "SnapOCR needs permission to capture your screen in order to recognize text. Your screen contents are processed entirely on-device and never sent anywhere.",
                    bundle: bundle,
                    comment: "Permission step description explaining why screen recording access is required"
                )
            )

            HStack(spacing: 10) {
                Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)

                Text(
                    isGranted
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
                .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.1))
                    .strokeBorder(statusColor.opacity(0.4), lineWidth: 1)
                    .accessibilityHidden(true)
            )

            if !isGranted {
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
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .onAppear {
            permissionService.startMonitoring()
        }
        .onDisappear {
            permissionService.stopMonitoring()
        }
    }
}

#if DEBUG
#Preview {
    PermissionStepView(
        permissionService: PermissionService(),
        settingsService: SettingsService()
    )
    .frame(width: 500, height: 380)
    .padding()
}
#endif
