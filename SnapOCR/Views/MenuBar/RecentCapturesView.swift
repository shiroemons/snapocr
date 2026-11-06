//
//  RecentCapturesView.swift
//  SnapOCR
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

    @State private var copyFeedback = CopyFeedback()
    @State private var hoveredRecordID: PersistentIdentifier?
    @State private var isHoveringShowAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Recent Captures", bundle: bundle, comment: "Section header for recent captures"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)

            // オフにしたのに消えていないと誤解されないよう、保存済みの履歴も出さない
            if settingsService.isHistoryEnabled {
                if historyService.recentRecords.isEmpty {
                    emptyState
                } else {
                    recentList
                }

                showAllButton
            } else {
                historyOffState
            }
        }
        .padding(.vertical, 4)
        .onDisappear { hoveredRecordID = nil; isHoveringShowAll = false; copyFeedback.reset() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        placeholder(
            String(
                localized: "No captures yet",
                bundle: bundle,
                comment: "Placeholder text when no capture history exists"
            )
        )
    }

    private var historyOffState: some View {
        placeholder(
            String(
                localized: "History is turned off",
                bundle: bundle,
                comment: "Placeholder text in recent captures when history is disabled"
            )
        )
    }

    private func placeholder(_ text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
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
                            systemName: copyFeedback.copiedRecordID == record.persistentModelID
                                ? "checkmark.circle.fill"
                                : "doc.on.clipboard"
                        )
                        .foregroundStyle(
                            copyFeedback.copiedRecordID == record.persistentModelID
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

                        RelativeTimeText(date: record.timestamp, locale: settingsService.locale)
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
                    String(
                        localized: "Copies this text to the clipboard",
                        bundle: bundle,
                        comment: "Accessibility hint for recent capture item button"
                    )
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
                String(localized: "Show All History...", bundle: bundle, comment: "Button to open full history window")
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
        let announcement = String(
            localized: "Copied to Clipboard",
            bundle: bundle,
            comment: "Toast notification title when OCR text is copied to clipboard"
        )
        copyFeedback.copy(record, announcement: announcement)
    }
}
