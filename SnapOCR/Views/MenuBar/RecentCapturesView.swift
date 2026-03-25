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
    let historyService: HistoryService
    let onShowHistory: () -> Void

    @State private var copiedRecordID: PersistentIdentifier?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                String(
                    localized: "Recent Captures",
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            Text(
                String(
                    localized: "No captures yet",
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

                        Text(record.text.prefix(30))
                            .lineLimit(1)
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
                    comment: "Button to open full history window"
                )
            )
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
    }

    // MARK: - Actions

    private func copyRecord(_ record: CaptureRecord) {
        _ = ClipboardService.copy(record.text)
        copiedRecordID = record.persistentModelID
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedRecordID == record.persistentModelID {
                copiedRecordID = nil
            }
        }
    }
}
