//
//  HistorySettingsView.swift
//  SnapOCR
//

import SwiftUI

/// 履歴設定タブ。履歴保存の有効化・保持件数・一括削除を管理する。
@MainActor
struct HistorySettingsView: View {
    let settingsService: SettingsService
    let historyService: HistoryService
    let onShowHistory: () -> Void

    @State private var showingDeleteConfirmation = false

    private var bundle: Bundle { settingsService.localizationBundle }
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
                    bundle: bundle,
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
                    bundle: bundle,
                    comment: "History storage description"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if settingsService.isHistoryEnabled {
                Picker(
                    String(
                        localized: "Maximum History Count",
                        bundle: bundle,
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
                    bundle: bundle,
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
                            bundle: bundle,
                            comment: "Button to open history window from settings"
                        )
                    )
                }
                .accessibilityLabel(
                    String(
                        localized: "Show all OCR history in a separate window",
                        bundle: bundle,
                        comment: "Accessibility label for the button that opens the full history window"
                    )
                )
            }
            HStack {
                Spacer()
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text(
                        String(
                            localized: "Delete All History",
                            bundle: bundle,
                            comment: "Button to delete all history"
                        )
                    )
                }
                .accessibilityLabel(
                    String(
                        localized: "Delete all OCR history permanently",
                        bundle: bundle,
                        comment: "Accessibility label for the destructive button that deletes all history"
                    )
                )
                .confirmationDialog(
                    String(
                        localized: "Delete All History?",
                        bundle: bundle,
                        comment: "Delete confirmation title"
                    ),
                    isPresented: $showingDeleteConfirmation
                ) {
                    Button(
                        String(
                            localized: "Delete All",
                            bundle: bundle,
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
                            bundle: bundle,
                            comment: "Delete confirmation message"
                        )
                    )
                }
            }
        } header: {
            Text(
                String(
                    localized: "Management",
                    bundle: bundle,
                    comment: "History management section header"
                )
            )
        }
    }
}
