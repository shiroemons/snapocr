//
//  HistoryRowView.swift
//  SnapOCR
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

    @State private var isExpanded = false
    @State private var isTruncated = false
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

            HStack(alignment: .top, spacing: 8) {
                if !isEditing {
                    Image(
                        systemName: isCopied
                            ? "checkmark.circle.fill"
                            : "doc.on.clipboard"
                    )
                    .foregroundStyle(
                        isCopied ? .green : .secondary
                    )
                    .frame(width: 16)
                    .onTapGesture(perform: onCopy)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.text)
                        .lineLimit(isExpanded ? nil : 3)
                        .fixedSize(
                            horizontal: false,
                            vertical: isExpanded
                        )
                        .font(.body)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onCopy)
                        .background {
                            // 展開中は切り詰められないので判定を止め、閉じたときにボタンがちらつかないよう前回の結果を残す
                            if !isExpanded { truncationDetector }
                        }

                    if isTruncated || isExpanded {
                        Button {
                            isExpanded.toggle()
                        } label: {
                            Text(
                                isExpanded
                                    ? String(
                                        localized: "Close",
                                        bundle: bundle,
                                        comment: "Button to collapse expanded history text"
                                    )
                                    : String(
                                        localized: "Show all",
                                        bundle: bundle,
                                        comment: "Button to expand truncated history text"
                                    )
                            )
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    RelativeTimeText(date: record.timestamp, locale: settingsService.locale)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .onTapGesture(perform: onCopy)
                }
                .animation(.easeInOut(duration: 0.25), value: isExpanded)
            }

            if !isEditing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(isHoveringDelete ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { isHoveringDelete = $0 }
                // 行の要素に統合されると、行を押す操作が削除になり、ヒントも行に漏れる。削除は行の操作として提供する
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(record.text)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onCopy)
        .accessibilityActions {
            // 編集中の onCopy は選択の切り替えになるので、コピーとしては出さない
            if !isEditing {
                Button(
                    String(
                        localized: "Copy text",
                        bundle: bundle,
                        comment: "Accessibility label for copy button in history row"
                    ),
                    action: onCopy
                )
                Button(
                    String(
                        localized: "Delete record",
                        bundle: bundle,
                        comment: "Accessibility label for delete button in history row"
                    ),
                    action: onDelete
                )
            }
        }
    }

    /// 全文の高さが、行数を制限した本文の高さに収まるかで切り詰めを判定する。
    private var truncationDetector: some View {
        ViewThatFits(in: .vertical) {
            Text(record.text)
                .font(.body)
                .hidden()
                .onAppear { isTruncated = false }
            Color.clear
                .onAppear { isTruncated = true }
        }
    }
}
