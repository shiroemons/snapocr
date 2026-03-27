//
//  CaptureActionView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct CaptureActionView: View {
    let settingsService: SettingsService
    let hotkeyLabel: String
    let isPermissionGranted: Bool
    let onCapture: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                onCapture()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.body)
                    Text(String(localized: "Capture Text", bundle: bundle, comment: "Main capture button label"))
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isPermissionGranted)
            .accessibilityLabel(
                String(localized: "Capture screen text", bundle: bundle, comment: "Accessibility label for capture button")
            )
            .accessibilityHint(
                isPermissionGranted
                    ? String(localized: "Double-click to start text capture", bundle: bundle, comment: "Accessibility hint for capture button when enabled")
                    : String(localized: "Screen recording permission required", bundle: bundle, comment: "Accessibility hint for capture button when disabled")
            )

            Text(String(localized: "Hotkey: \(hotkeyLabel)", bundle: bundle, comment: "Hotkey label shown below capture button"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    VStack {
        CaptureActionView(settingsService: SettingsService(), hotkeyLabel: "⌃⇧O", isPermissionGranted: true) {
            // capture
        }
        Divider()
        CaptureActionView(settingsService: SettingsService(), hotkeyLabel: "⌃⇧O", isPermissionGranted: false) {
            // capture
        }
    }
    .frame(width: 320)
    .padding()
}
#endif
