//
//  HistoryRowView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftData
import SwiftUI

@MainActor
struct HistoryRowView: View {
    let record: CaptureRecord
    let settingsService: SettingsService
    let isCopied: Bool
    let isEditing: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    @State private var isHoveringDelete = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if isEditing {
                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundStyle(isSelected ? .blue : .secondary)
                .frame(width: 16)
            }

            Button(action: onCopy) {
                HStack(alignment: .top, spacing: 8) {
                    if !isEditing {
                        Image(
                            systemName: isCopied
                                ? "checkmark.circle.fill"
                                : "doc.on.clipboard"
                        )
                        .foregroundStyle(isCopied ? .green : .secondary)
                        .frame(width: 16)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.text)
                            .lineLimit(3)
                            .font(.body)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                        Text(
                            record.timestamp,
                            format: .relative(
                                presentation: .named
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(
                    localized: "Copy text",
                    bundle: bundle,
                    comment: "Accessibility label for copy button in history row"
                )
            )
            .accessibilityHint(
                String(
                    localized: "Copies the recognized text to the clipboard",
                    bundle: bundle,
                    comment: "Accessibility hint for copy button in history row"
                )
            )

            if !isEditing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(isHoveringDelete ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { isHoveringDelete = $0 }
                .accessibilityLabel(
                    String(
                        localized: "Delete record",
                        bundle: bundle,
                        comment: "Accessibility label for delete button in history row"
                    )
                )
                .accessibilityHint(
                    String(
                        localized: "Permanently deletes this history record",
                        bundle: bundle,
                        comment: "Accessibility hint for delete button in history row"
                    )
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(record.text)
    }
}
