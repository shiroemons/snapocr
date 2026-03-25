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

    /// サポートする言語の定義
    private static let supportedLanguages: [(code: String, displayName: String)] = [
        ("ja", String(localized: "Japanese", comment: "Japanese language option in OCR settings")),
        ("en", String(localized: "English", comment: "English language option in OCR settings")),
    ]

    var body: some View {
        Form {
            Section {
                ForEach(Self.supportedLanguages, id: \.code) { language in
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
                }
            } header: {
                Text(String(localized: "Recognition Languages", comment: "OCR language selection section header"))
            } footer: {
                Text(String(localized: "At least one language must be selected.", comment: "OCR language selection footer note"))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
