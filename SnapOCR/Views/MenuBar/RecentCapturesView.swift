//
//  RecentCapturesView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftData
import SwiftUI

/// メニューバーパネル内の最近のキャプチャ履歴セクション。
/// 直近5件のOCR結果を表示し、クリックで再コピーできる。
@MainActor
struct RecentCapturesView: View {
    private static let textLineLimit = 5
    private static let hoverBackgroundColor = Color.primary.opacity(0.08)

    let settingsService: SettingsService
    let historyService: HistoryService
    let onShowHistory: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    @State private var copiedRecordID: PersistentIdentifier?
    @State private var hoveredRecordID: PersistentIdentifier?
    @State private var isHoveringShowAll = false
    @State private var copyResetTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                String(
                    localized: "Recent Captures",
                    bundle: bundle,
                    comment: "Section header for recent captures"
                )
            )
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)

            if historyService.recentRecords.isEmpty {
                emptyState
            } else {
                recentList
            }

            showAllButton
        }
        .padding(.vertical, 4)
        .onDisappear { hoveredRecordID = nil; isHoveringShowAll = false; copyResetTask?.cancel() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            Text(
                String(
                    localized: "No captures yet",
                    bundle: bundle,
                    comment: "Placeholder text when no capture history exists"
                )
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.vertical, 16)
    }

    // MARK: - Recent List

    private var recentList: some View {
        VStack(spacing: 0) {
            ForEach(historyService.recentRecords) { record in
                Button {
                    copyRecord(record)
                } label: {
                    HStack(spacing: 8) {
                        Image(
                            systemName: copiedRecordID == record.persistentModelID
                                ? "checkmark.circle.fill"
                                : "doc.on.clipboard"
                        )
                        .foregroundStyle(
                            copiedRecordID == record.persistentModelID
                                ? .green
                                : .secondary
                        )
                        .frame(width: 14)
                        .font(.caption)
                        .accessibilityHidden(true)

                        Text(record.text)
                            .lineLimit(Self.textLineLimit)
                            .truncationMode(.tail)
                            .font(.caption)
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
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(record.text)
                .accessibilityHint(
                    String(localized: "Copies this text to the clipboard", bundle: bundle, comment: "Accessibility hint for recent capture item button")
                )
                .onHover { hovering in
                    hoveredRecordID = hovering ? record.persistentModelID : nil
                }
                .background(
                    hoveredRecordID == record.persistentModelID
                        ? Self.hoverBackgroundColor
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .help(record.text)
            }
        }
    }

    // MARK: - Show All

    private var showAllButton: some View {
        Button {
            onShowHistory()
        } label: {
            Text(
                String(
                    localized: "Show All History...",
                    bundle: bundle,
                    comment: "Button to open full history window"
                )
            )
            .underline(isHoveringShowAll)
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        .onHover { isHoveringShowAll = $0 }
    }

    // MARK: - Actions

    private func copyRecord(_ record: CaptureRecord) {
        guard ClipboardService.copy(record.text) else { return }
        copiedRecordID = record.persistentModelID
        copyResetTask?.cancel()
        copyResetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedRecordID == record.persistentModelID {
                copiedRecordID = nil
            }
        }
    }
}
