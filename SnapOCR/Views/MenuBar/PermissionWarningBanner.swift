//
//  PermissionWarningBanner.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct PermissionWarningBanner: View {
    let settingsService: SettingsService
    let onOpenSettings: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(
                    localized: "Screen recording permission required",
                    bundle: bundle,
                    comment: "Permission warning title"
                ))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(String(
                    localized: "Grant access in System Settings to use OCR capture.",
                    bundle: bundle,
                    comment: "Permission warning description"
                ))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                onOpenSettings()
            } label: {
                Text(String(
                    localized: "Open Settings",
                    bundle: bundle,
                    comment: "Button to open System Settings for permission"
                ))
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel(
                String(
                    localized: "Open System Settings to grant screen recording permission",
                    bundle: bundle,
                    comment: "Accessibility label for open settings button in permission warning"
                )
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1)
                        .accessibilityHidden(true)
                )
                .accessibilityHidden(true)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

#if DEBUG
#Preview {
    PermissionWarningBanner(settingsService: SettingsService()) {
        // open settings
    }
    .frame(width: 320)
    .padding()
}
#endif
