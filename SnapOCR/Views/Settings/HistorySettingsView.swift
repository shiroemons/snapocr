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
    @State private var showingDisableConfirmation = false
    /// 確認待ちの新しい上限。確認中は Picker に表示し、確定するまで設定には書き込まない。
    @State private var pendingMaxCount: Int?

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
        Section(String(localized: "Storage", bundle: bundle, comment: "History storage section header")) {
            Toggle(
                String(localized: "Save OCR History", bundle: bundle, comment: "Toggle for history saving"),
                isOn: Binding(
                    get: { settingsService.isHistoryEnabled },
                    set: { requestHistoryEnabled($0) }
                )
            )
            .confirmationDialog(
                String(
                    localized: "Turn Off OCR History?",
                    bundle: bundle,
                    comment: "Confirmation title when turning off history while records exist"
                ),
                isPresented: $showingDisableConfirmation
            ) {
                Button(
                    String(
                        localized: "Delete History",
                        bundle: bundle,
                        comment: "Button to delete existing history and turn off history saving"
                    ),
                    role: .destructive
                ) {
                    historyService.deleteAll()
                    settingsService.isHistoryEnabled = false
                }
                Button(
                    String(
                        localized: "Keep History",
                        bundle: bundle,
                        comment: "Button to keep existing history and turn off history saving"
                    )
                ) {
                    settingsService.isHistoryEnabled = false
                }
            } message: {
                Text(
                    String(
                        localized: "You can delete the saved history or keep it. Deleted history cannot be restored.",
                        bundle: bundle,
                        comment: "Confirmation message when turning off history while records exist"
                    )
                )
            }

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
                    String(localized: "Maximum History Count", bundle: bundle, comment: "Picker for max history count"),
                    selection: Binding(
                        get: { pendingMaxCount ?? settingsService.maxHistoryCount },
                        set: { requestMaxHistoryCount($0) }
                    )
                ) {
                    ForEach(maxCountOptions, id: \.self) { count in
                        Text(count, format: .number)
                            .tag(count)
                    }
                }
                .confirmationDialog(
                    String(
                        localized: "Lower the History Limit?",
                        bundle: bundle,
                        comment: "Confirmation title when a lower history limit would delete records"
                    ),
                    isPresented: Binding(
                        get: { pendingMaxCount != nil },
                        set: { isPresented in
                            if !isPresented {
                                pendingMaxCount = nil
                            }
                        }
                    ),
                    presenting: pendingMaxCount
                ) { newLimit in
                    Button(
                        String(
                            localized: "Lower Limit and Delete",
                            bundle: bundle,
                            comment: "Button to apply a lower history limit and delete older records"
                        ),
                        role: .destructive
                    ) {
                        applyMaxHistoryCount(newLimit)
                    }
                } message: { newLimit in
                    Text(
                        String(
                            // swiftlint:disable:next line_length
                            localized: "Only the \(newLimit) most recent records will be kept. Older records will be permanently deleted.",
                            bundle: bundle,
                            comment: "Confirmation message when a lower history limit would delete records"
                        )
                    )
                }
            }
        }
    }

    private func requestHistoryEnabled(_ isEnabled: Bool) {
        if !isEnabled, historyService.recordCount() > 0 {
            showingDisableConfirmation = true
        } else {
            settingsService.isHistoryEnabled = isEnabled
        }
    }

    private func requestMaxHistoryCount(_ newLimit: Int) {
        if historyService.recordCount() > newLimit {
            pendingMaxCount = newLimit
        } else {
            applyMaxHistoryCount(newLimit)
        }
    }

    private func applyMaxHistoryCount(_ newLimit: Int) {
        settingsService.maxHistoryCount = newLimit
        historyService.trimToLimit(newLimit)
    }

    // MARK: - Management

    private var managementSection: some View {
        Section(String(localized: "Management", bundle: bundle, comment: "History management section header")) {
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
                .accessibilityHint(String(
                    localized: "Show all OCR history in a separate window",
                    bundle: bundle,
                    comment: "Accessibility hint for the button that opens the full history window"
                ))
            }
            HStack {
                Spacer()
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text(
                        String(localized: "Delete All History", bundle: bundle, comment: "Button to delete all history")
                    )
                }
                .accessibilityHint(String(
                    localized: "Delete all OCR history permanently",
                    bundle: bundle,
                    comment: "Accessibility hint for the destructive button that deletes all history"
                ))
                .confirmationDialog(
                    String(localized: "Delete All History?", bundle: bundle, comment: "Delete confirmation title"),
                    isPresented: $showingDeleteConfirmation
                ) {
                    Button(
                        String(localized: "Delete All", bundle: bundle, comment: "Confirm delete all button"),
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
        }
    }
}
