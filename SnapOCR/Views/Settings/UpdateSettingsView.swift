//
//  UpdateSettingsView.swift
//  SnapOCR
//

@preconcurrency import Sparkle
import SwiftUI

@MainActor
struct UpdateSettingsView: View {
    let settingsService: SettingsService
    let updater: SPUUpdater

    // SPUUpdater は Observation に対応していないので、KVO の値を状態に写して再描画につなげる
    @State private var canCheckForUpdates = false
    @State private var automaticallyChecksForUpdates = false
    @State private var allowsAutomaticUpdates = false
    @State private var lastUpdateCheckDate: Date?

    private var bundle: Bundle { settingsService.localizationBundle }

    var body: some View {
        Form {
            Section(String(
                localized: "Automatic Updates",
                bundle: bundle,
                comment: "Section header for automatic update settings"
            )) {
                Toggle(
                    String(
                        localized: "Automatically check for updates",
                        bundle: bundle,
                        comment: "Toggle label for automatic update checks"
                    ),
                    isOn: Binding(
                        get: { updater.automaticallyChecksForUpdates },
                        set: { updater.automaticallyChecksForUpdates = $0 }
                    )
                )

                Picker(
                    String(
                        localized: "Check interval",
                        bundle: bundle,
                        comment: "Picker label for update check interval"
                    ),
                    selection: Binding(
                        get: { updater.updateCheckInterval },
                        set: { updater.updateCheckInterval = $0 }
                    )
                ) {
                    Text(String(localized: "Every hour", bundle: bundle, comment: "Update check interval option"))
                        .tag(TimeInterval(3600))
                    Text(String(localized: "Every 6 hours", bundle: bundle, comment: "Update check interval option"))
                        .tag(TimeInterval(21600))
                    Text(String(localized: "Every 12 hours", bundle: bundle, comment: "Update check interval option"))
                        .tag(TimeInterval(43200))
                    Text(String(localized: "Every day", bundle: bundle, comment: "Update check interval option"))
                        .tag(TimeInterval(86400))
                    Text(String(localized: "Every week", bundle: bundle, comment: "Update check interval option"))
                        .tag(TimeInterval(604800))
                }

                Toggle(
                    String(
                        localized: "Automatically download and install updates",
                        bundle: bundle,
                        comment: "Toggle label for automatic update installation"
                    ),
                    isOn: Binding(
                        get: { updater.automaticallyDownloadsUpdates },
                        set: { updater.automaticallyDownloadsUpdates = $0 }
                    )
                )
                .disabled(!automaticallyChecksForUpdates || !allowsAutomaticUpdates)
            }

            Section {
                HStack {
                    Spacer()
                    Button(String(
                        localized: "Check for Updates Now",
                        bundle: bundle,
                        comment: "Button to manually check for updates"
                    )) {
                        updater.checkForUpdates()
                    }
                    .disabled(!canCheckForUpdates)
                }

                if let lastUpdateCheckDate {
                    LabeledContent(
                        String(localized: "Last checked", bundle: bundle, comment: "Label for last update check date")
                    ) {
                        Text(lastUpdateCheckDate, style: .relative)
                            .foregroundStyle(.secondary)
                            .environment(\.locale, settingsService.locale)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            lastUpdateCheckDate = updater.lastUpdateCheckDate
        }
        .onReceive(updater.publisher(for: \.canCheckForUpdates)) { newValue in
            canCheckForUpdates = newValue
            // lastUpdateCheckDate は KVO に対応していないので、更新セッションの前後で変わるこの値に合わせて読み直す
            lastUpdateCheckDate = updater.lastUpdateCheckDate
        }
        .onReceive(updater.publisher(for: \.automaticallyChecksForUpdates)) { automaticallyChecksForUpdates = $0 }
        .onReceive(updater.publisher(for: \.allowsAutomaticUpdates)) { allowsAutomaticUpdates = $0 }
    }
}
