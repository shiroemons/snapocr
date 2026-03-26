//
//  HistoryRowView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftData
import SwiftUI

struct HistoryRowView: View {
    let record: CaptureRecord
    let isCopied: Bool
    let isEditing: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

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

                        HStack(spacing: 8) {
                            Text(
                                record.timestamp,
                                format: .relative(
                                    presentation: .named
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if !record.recognizedLanguages.isEmpty {
                                Text(
                                    record.recognizedLanguages
                                        .joined(separator: ", ")
                                )
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    .quaternary,
                                    in: RoundedRectangle(
                                        cornerRadius: 3
                                    )
                                )
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isEditing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(isHoveringDelete ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { isHoveringDelete = $0 }
            }
        }
    }
}
