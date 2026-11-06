//
//  HistoryListView.swift
//  SnapOCR
//

import SwiftData
import SwiftUI

/// OCR履歴の一覧表示ビュー。
/// 検索・再コピー・削除機能を提供する。
@MainActor
struct HistoryListView: View {
    let settingsService: SettingsService
    let historyService: HistoryService

    private var bundle: Bundle { settingsService.localizationBundle }

    @State private var searchText = ""
    @State private var copyFeedback = CopyFeedback()
    @State private var isEditing = false
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var showDeleteAllConfirmation = false

    var body: some View {
        let records = historyService.fetchAll(searchText: searchText)
        VStack(spacing: 0) {
            searchField(records: records)
            if records.isEmpty {
                emptyState
            } else {
                recordsList(records: records)
            }
        }
        .confirmationDialog(
            String(
                localized: "Delete All History",
                bundle: bundle,
                comment: "Confirmation dialog title for delete all"
            ),
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                String(localized: "Delete All", bundle: bundle, comment: "Confirmation button to delete all history"),
                role: .destructive
            ) {
                historyService.deleteAll()
            }
        } message: {
            Text(
                String(
                    localized: "This will permanently delete all OCR history.",
                    bundle: bundle,
                    comment: "Confirmation dialog message for delete all"
                )
            )
        }
        .onDisappear { copyFeedback.reset() }
    }
}

// MARK: - Search

extension HistoryListView {
    private func searchField(records: [CaptureRecord]) -> some View {
        HStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    String(localized: "Search history...", bundle: bundle, comment: "History search placeholder"),
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
                            bundle: bundle,
                            comment: "Accessibility label for clear search button"
                        )
                    )
                }
            }
            .padding(8)

            Divider()
                .frame(height: 20)
                .accessibilityHidden(true)

            editModeButton(records: records)
        }
        .background(.bar)
    }

    private func editModeButton(records: [CaptureRecord]) -> some View {
        Button {
            isEditing.toggle()
            if !isEditing { selectedIDs = [] }
        } label: {
            if isEditing {
                Text(String(localized: "Done", bundle: bundle, comment: "Exit edit mode button"))
            } else {
                Text(String(localized: "Select", bundle: bundle, comment: "Enter edit mode button"))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        // 編集中に全件が消えても編集モードを抜けられるよう、編集中は無効にしない
        .disabled(records.isEmpty && !isEditing)
        .frame(width: 60)
        .accessibilityLabel(
            isEditing
                ? String(
                    localized: "Done selecting",
                    bundle: bundle,
                    comment: "Accessibility label for done button in edit mode"
                )
                : String(
                    localized: "Select items",
                    bundle: bundle,
                    comment: "Accessibility label for select button"
                )
        )
    }
}

// MARK: - Empty State

extension HistoryListView {
    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                String(localized: "No History", bundle: bundle, comment: "Empty history title"),
                systemImage: "clock.arrow.circlepath"
            )
        } description: {
            if searchText.isEmpty {
                Text(
                    String(
                        localized: "Captured text will appear here.",
                        bundle: bundle,
                        comment: "Empty history description"
                    )
                )
            } else {
                Text(
                    String(localized: "No results for \"\(searchText)\".", bundle: bundle, comment: "No search results")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Records List

extension HistoryListView {
    private func recordsList(records: [CaptureRecord]) -> some View {
        VStack(spacing: 0) {
            List {
                ForEach(records) { record in
                    let recordID = record.persistentModelID
                    HistoryRowView(
                        record: record,
                        settingsService: settingsService,
                        isCopied: copyFeedback.copiedRecordID == recordID,
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
                        Button(String(localized: "Copy", bundle: bundle, comment: "Context menu copy")) {
                            copyRecord(record)
                        }
                        Divider()
                        Button(
                            String(localized: "Delete", bundle: bundle, comment: "Context menu delete"),
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
                editingToolbar(records: records)
            }
        }
    }

    private func editingToolbar(records: [CaptureRecord]) -> some View {
        // 検索で隠れた項目を巻き込んで削除しないよう、操作と表示は見えている選択だけを対象にする
        let visibleIDs = Set(records.map(\.persistentModelID))
        let visibleSelection = selectedIDs.intersection(visibleIDs)
        let isAllSelected = visibleSelection.count == records.count

        return HStack {
            Button(role: .destructive) {
                deleteSelected(visibleSelection)
            } label: {
                Text(
                    String(
                        localized: "Delete \(visibleSelection.count) Selected",
                        bundle: bundle,
                        comment: "Delete selected items button"
                    )
                )
            }
            .disabled(visibleSelection.isEmpty)
            .accessibilityLabel(
                String(
                    localized: "Delete \(visibleSelection.count) selected items",
                    bundle: bundle,
                    comment: "Accessibility label for delete selected button"
                )
            )

            Spacer()

            selectAllButton(visibleIDs: visibleIDs, isAllSelected: isAllSelected)

            Button(role: .destructive) {
                showDeleteAllConfirmation = true
            } label: {
                Text(String(localized: "Delete All", bundle: bundle, comment: "Delete all history button"))
            }
            .disabled(records.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func selectAllButton(visibleIDs: Set<PersistentIdentifier>, isAllSelected: Bool) -> some View {
        Button {
            if isAllSelected {
                selectedIDs.subtract(visibleIDs)
            } else {
                selectedIDs.formUnion(visibleIDs)
            }
        } label: {
            if isAllSelected {
                Text(String(localized: "Deselect All", bundle: bundle, comment: "Deselect all items button"))
            } else {
                Text(String(localized: "Select All", bundle: bundle, comment: "Select all items button"))
            }
        }
        .accessibilityLabel(
            isAllSelected
                ? String(
                    localized: "Deselect all items",
                    bundle: bundle,
                    comment: "Accessibility label for deselect all button"
                )
                : String(
                    localized: "Select all items",
                    bundle: bundle,
                    comment: "Accessibility label for select all button"
                )
        )
    }
}

// MARK: - Actions

extension HistoryListView {
    private func copyRecord(_ record: CaptureRecord) {
        let announcement = String(
            localized: "Copied to Clipboard",
            bundle: bundle,
            comment: "Toast notification title when OCR text is copied to clipboard"
        )
        copyFeedback.copy(record, announcement: announcement)
    }

    private func toggleSelection(_ id: PersistentIdentifier) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func deleteSelected(_ ids: Set<PersistentIdentifier>) {
        historyService.delete(ids: ids)
        selectedIDs.subtract(ids)
    }
}
