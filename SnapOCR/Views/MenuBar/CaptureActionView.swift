//
//  CaptureActionView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct CaptureActionView: View {
    let hotkeyLabel: String
    let isPermissionGranted: Bool
    let onCapture: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button {
                onCapture()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.body)
                    Text(String(localized: "Capture Text", comment: "Main capture button label"))
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isPermissionGranted)
            .accessibilityHint(
                isPermissionGranted
                    ? String(localized: "Double-click to start text capture", comment: "Accessibility hint for capture button when enabled")
                    : String(localized: "Screen recording permission required", comment: "Accessibility hint for capture button when disabled")
            )

            Text(String(localized: "Hotkey: \(hotkeyLabel)", comment: "Hotkey label shown below capture button"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#if DEBUG
#Preview {
    VStack {
        CaptureActionView(hotkeyLabel: "⌃⇧O", isPermissionGranted: true) {
            // capture
        }
        Divider()
        CaptureActionView(hotkeyLabel: "⌃⇧O", isPermissionGranted: false) {
            // capture
        }
    }
    .frame(width: 320)
    .padding()
}
#endif
