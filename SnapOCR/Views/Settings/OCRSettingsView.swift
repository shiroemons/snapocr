//
//  OCRSettingsView.swift
//  SnapOCR
//

import SwiftUI

@MainActor
struct OCRSettingsView: View {
    let settingsService: SettingsService

    private var bundle: Bundle { settingsService.localizationBundle }

    private var warnings: [OCRLanguageWarning] {
        OCRLanguageWarnings.warnings(for: settingsService.ocrLanguages)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Label {
                    Text(String(
                        // swiftlint:disable:next line_length
                        localized: "Narrowing recognition languages improves accuracy. At least one language must be selected.",
                        bundle: bundle,
                        comment: "OCR settings recommendation"
                    ))
                } icon: {
                    Image(systemName: "info.circle")
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                if !warnings.isEmpty {
                    Divider()
                    ForEach(warnings) { warning in
                        Label {
                            Text(String(
                                localized: String.LocalizationValue(warning.messageKey),
                                bundle: bundle,
                                comment: "OCR language warning message"
                            ))
                        } icon: {
                            Image(systemName: warning.iconName)
                                .foregroundStyle(.orange)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)

            Divider()

            Form {
                ForEach(OCRLanguageGroup.allCases) { group in
                    Section(String(
                        localized: String.LocalizationValue(group.displayNameKey),
                        bundle: bundle,
                        comment: "OCR language group header"
                    )) {
                        ForEach(OCRLanguageDefinition.languages(for: group)) { language in
                            let languageName = String(
                                localized: String.LocalizationValue(language.displayNameKey),
                                bundle: bundle,
                                comment: "OCR language option"
                            )
                            Toggle(
                                languageName,
                                isOn: languageBinding(for: language)
                            )
                            .disabled(settingsService.ocrLanguages == [language.code])
                            .accessibilityHint(languageToggleHint(for: languageName))
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .padding()
    }

    private func languageBinding(for language: OCRLanguageDefinition) -> Binding<Bool> {
        Binding(
            get: { settingsService.ocrLanguages.contains(language.code) },
            set: { isOn in
                var languages = settingsService.ocrLanguages
                if isOn {
                    if !languages.contains(language.code) {
                        languages.append(language.code)
                    }
                } else {
                    if languages.count > 1 {
                        languages.removeAll { $0 == language.code }
                    }
                }
                settingsService.ocrLanguages = languages
            }
        )
    }

    private func languageToggleHint(for languageName: String) -> String {
        String(
            localized: "Enable or disable \(languageName) text recognition. At least one language must remain enabled.",
            bundle: bundle,
            comment: "Accessibility hint for OCR language toggle describing its effect"
        )
    }
}
