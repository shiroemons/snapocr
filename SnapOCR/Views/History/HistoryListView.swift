//
//  HistoryListView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftData
import SwiftUI

/// OCR履歴の一覧表示ビュー。
/// 検索・再コピー・削除機能を提供する。
@MainActor
struct HistoryListView: View {
    let historyService: HistoryService

    @State private var searchText = ""
    @State private var copiedRecordID: PersistentIdentifier?

    private var records: [CaptureRecord] {
        historyService.fetchAll(searchText: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            if records.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(
                String(
                    localized: "Search history...",
                    comment: "History search placeholder"
                ),
                text: $searchText
            )
            .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.bar)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "No History",
                    comment: "Empty history title"
                ),
                systemImage: "clock.arrow.circlepath"
            )
        } description: {
            if searchText.isEmpty {
                Text(
                    String(
                        localized: "Captured text will appear here.",
                        comment: "Empty history description"
                    )
                )
            } else {
                Text(
                    String(
                        localized: "No results for \"\(searchText)\".",
                        comment: "No search results"
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Records List

    private var recordsList: some View {
        List {
            ForEach(records) { record in
                HistoryRowView(
                    record: record,
                    isCopied: copiedRecordID == record.persistentModelID
                ) {
                    copyRecord(record)
                }
                .contextMenu {
                    Button(
                        String(
                            localized: "Copy",
                            comment: "Context menu copy"
                        )
                    ) {
                        copyRecord(record)
                    }
                    Divider()
                    Button(
                        String(
                            localized: "Delete",
                            comment: "Context menu delete"
                        ),
                        role: .destructive
                    ) {
                        historyService.delete(record)
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    historyService.delete(records[index])
                }
            }
        }
        .listStyle(.inset)
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

// MARK: - History Row

private struct HistoryRowView: View {
    let record: CaptureRecord
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        Button(action: onCopy) {
            HStack(alignment: .top, spacing: 8) {
                Image(
                    systemName: isCopied
                        ? "checkmark.circle.fill"
                        : "doc.on.clipboard"
                )
                .foregroundStyle(isCopied ? .green : .secondary)
                .frame(width: 16)

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
    }
}
