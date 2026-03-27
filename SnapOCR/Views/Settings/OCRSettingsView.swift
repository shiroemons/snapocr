//
//  OCRSettingsView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct OCRSettingsView: View {
    let settingsService: SettingsService

    private var bundle: Bundle { settingsService.localizationBundle }

    /// サポートする言語の定義
    private var supportedLanguages: [(code: String, displayName: String)] {
        [
            ("ja", String(localized: "Japanese", bundle: bundle, comment: "Japanese language option in OCR settings")),
            ("en", String(localized: "English", bundle: bundle, comment: "English language option in OCR settings")),
        ]
    }

    private func languageToggleHint(for displayName: String) -> String {
        // swiftlint:disable:next line_length
        String(localized: "Enable or disable \(displayName) text recognition. At least one language must remain enabled.", bundle: bundle, comment: "Accessibility hint for OCR language toggle describing its effect")
    }

    var body: some View {
        Form {
            Section {
                ForEach(supportedLanguages, id: \.code) { language in
                    Toggle(
                        language.displayName,
                        isOn: Binding(
                            get: { settingsService.ocrLanguages.contains(language.code) },
                            set: { isOn in
                                var languages = settingsService.ocrLanguages
                                if isOn {
                                    if !languages.contains(language.code) {
                                        languages.append(language.code)
                                    }
                                } else {
                                    // 最低1言語は有効にしておく
                                    if languages.count > 1 {
                                        languages.removeAll { $0 == language.code }
                                    }
                                }
                                settingsService.ocrLanguages = languages
                            }
                        )
                    )
                    .accessibilityHint(languageToggleHint(for: language.displayName))
                }
            } header: {
                Text(String(
                    localized: "Recognition Languages",
                    bundle: bundle,
                    comment: "OCR language selection section header"
                ))
            } footer: {
                Text(String(
                    localized: "At least one language must be selected.",
                    bundle: bundle,
                    comment: "OCR language selection footer note"
                ))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
