//
//  HistorySettingsView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

/// 履歴設定タブ。履歴保存の有効化・保持件数・一括削除を管理する。
@MainActor
struct HistorySettingsView: View {
    let settingsService: SettingsService
    let historyService: HistoryService
    let onShowHistory: () -> Void

    @State private var showingDeleteConfirmation = false

    private let maxCountOptions = [50, 100, 200, 500]

    var body: some View {
        Form {
            storageSection
            managementSection
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Storage

    private var storageSection: some View {
        Section {
            Toggle(
                String(
                    localized: "Save OCR History",
                    comment: "Toggle for history saving"
                ),
                isOn: Binding(
                    get: { settingsService.isHistoryEnabled },
                    set: { settingsService.isHistoryEnabled = $0 }
                )
            )

            Text(
                String(
                    localized: "Save recognized text from screen captures for later reference.",
                    comment: "History storage description"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if settingsService.isHistoryEnabled {
                Picker(
                    String(
                        localized: "Maximum History Count",
                        comment: "Picker for max history count"
                    ),
                    selection: Binding(
                        get: { settingsService.maxHistoryCount },
                        set: {
                            settingsService.maxHistoryCount = $0
                            historyService.trimToLimit($0)
                        }
                    )
                ) {
                    ForEach(maxCountOptions, id: \.self) { count in
                        Text("\(count)")
                            .tag(count)
                    }
                }
            }
        } header: {
            Text(
                String(
                    localized: "Storage",
                    comment: "History storage section header"
                )
            )
        }
    }

    // MARK: - Management

    private var managementSection: some View {
        Section {
            HStack {
                Spacer()
                Button {
                    onShowHistory()
                } label: {
                    Text(
                        String(
                            localized: "Show All History",
                            comment: "Button to open history window from settings"
                        )
                    )
                }
            }
            HStack {
                Spacer()
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text(
                        String(
                            localized: "Delete All History",
                            comment: "Button to delete all history"
                        )
                    )
                }
                .confirmationDialog(
                    String(
                        localized: "Delete All History?",
                        comment: "Delete confirmation title"
                    ),
                    isPresented: $showingDeleteConfirmation
                ) {
                    Button(
                        String(
                            localized: "Delete All",
                            comment: "Confirm delete all button"
                        ),
                        role: .destructive
                    ) {
                        historyService.deleteAll()
                    }
                } message: {
                    Text(
                        String(
                            localized: "This action cannot be undone.",
                            comment: "Delete confirmation message"
                        )
                    )
                }
            }
        } header: {
            Text(
                String(
                    localized: "Management",
                    comment: "History management section header"
                )
            )
        }
    }
}
