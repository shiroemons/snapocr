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
    @State private var isEditing = false
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var showDeleteAllConfirmation = false
    @State private var copyResetTask: Task<Void, Never>?

    private var records: [CaptureRecord] {
        // Workaround: access @Observable tracked property to trigger SwiftUI re-evaluation
        // when history data changes. Without this, fetchAll results wouldn't update reactively.
        _ = historyService.recentRecords
        return historyService.fetchAll(searchText: searchText)
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
        .confirmationDialog(
            String(
                localized: "Delete All History",
                comment: "Confirmation dialog title for delete all"
            ),
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                String(
                    localized: "Delete All",
                    comment: "Confirmation button to delete all history"
                ),
                role: .destructive
            ) {
                historyService.deleteAll()
            }
        } message: {
            Text(
                String(
                    localized: "This will permanently delete all OCR history.",
                    comment: "Confirmation dialog message for delete all"
                )
            )
        }
        .onDisappear { copyResetTask?.cancel() }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 0) {
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
                    .accessibilityLabel(
                        String(
                            localized: "Clear search",
                            comment: "Accessibility label for clear search button"
                        )
                    )
                }
            }
            .padding(8)

            Divider()
                .frame(height: 20)
                .accessibilityHidden(true)

            Button {
                isEditing.toggle()
                if !isEditing { selectedIDs = [] }
            } label: {
                if isEditing {
                    Text(
                        String(
                            localized: "Done",
                            comment: "Exit edit mode button"
                        )
                    )
                } else {
                    Text(
                        String(
                            localized: "Select",
                            comment: "Enter edit mode button"
                        )
                    )
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .disabled(records.isEmpty)
            .frame(width: 60)
            .accessibilityLabel(
                isEditing
                    ? String(
                        localized: "Done selecting",
                        comment: "Accessibility label for done button in edit mode"
                    )
                    : String(
                        localized: "Select items",
                        comment: "Accessibility label for select button"
                    )
            )
        }
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
        VStack(spacing: 0) {
            List {
                ForEach(records) { record in
                    let recordID = record.persistentModelID
                    HistoryRowView(
                        record: record,
                        isCopied: copiedRecordID == recordID,
                        isEditing: isEditing,
                        isSelected: selectedIDs.contains(recordID),
                        onCopy: {
                            if isEditing {
                                toggleSelection(recordID)
                            } else {
                                copyRecord(record)
                            }
                        },
                        onDelete: {
                            historyService.delete(record)
                        }
                    )
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
                    let recordsToDelete = offsets.map { records[$0] }
                    for record in recordsToDelete {
                        historyService.delete(record)
                    }
                }
            }
            .listStyle(.inset)

            if isEditing {
                editingToolbar
            }
        }
    }

    // MARK: - Editing Toolbar

    private var editingToolbar: some View {
        HStack {
            Button(
                role: .destructive
            ) {
                deleteSelected()
            } label: {
                Text(
                    String(
                        localized: "Delete \(selectedIDs.count) Selected",
                        comment: "Delete selected items button"
                    )
                )
            }
            .disabled(selectedIDs.isEmpty)
            .accessibilityLabel(
                String(
                    localized: "Delete \(selectedIDs.count) selected items",
                    comment: "Accessibility label for delete selected button"
                )
            )

            Spacer()

            Button {
                if selectedIDs.count == records.count {
                    selectedIDs = []
                } else {
                    selectedIDs = Set(records.map(\.persistentModelID))
                }
            } label: {
                if selectedIDs.count == records.count {
                    Text(
                        String(
                            localized: "Deselect All",
                            comment: "Deselect all items button"
                        )
                    )
                } else {
                    Text(
                        String(
                            localized: "Select All",
                            comment: "Select all items button"
                        )
                    )
                }
            }
            .accessibilityLabel(
                selectedIDs.count == records.count
                    ? String(
                        localized: "Deselect all items",
                        comment: "Accessibility label for deselect all button"
                    )
                    : String(
                        localized: "Select all items",
                        comment: "Accessibility label for select all button"
                    )
            )

            Button(
                role: .destructive
            ) {
                showDeleteAllConfirmation = true
            } label: {
                Text(
                    String(
                        localized: "Delete All",
                        comment: "Delete all history button"
                    )
                )
            }
            .disabled(records.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
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

    private func toggleSelection(_ id: PersistentIdentifier) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func deleteSelected() {
        historyService.delete(ids: selectedIDs)
        selectedIDs = []
    }
}
