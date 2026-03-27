//
//  GeneralSettingsView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct GeneralSettingsView: View {
    let permissionService: PermissionService
    let settingsService: SettingsService
    let loginItemService: LoginItemService
    let onShowOnboarding: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: permissionService.isScreenCapturePermitted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(permissionService.isScreenCapturePermitted ? .green : .yellow)
                        .accessibilityHidden(true)
                    Text(
                        permissionService.isScreenCapturePermitted
                            ? String(localized: "Screen Recording: Allowed", bundle: bundle, comment: "Screen recording permission granted status")
                            : String(localized: "Screen Recording: Not Allowed", bundle: bundle, comment: "Screen recording permission denied status")
                    )
                    Spacer()
                    if !permissionService.isScreenCapturePermitted {
                        Button(String(localized: "Open System Settings", bundle: bundle, comment: "Button to open System Settings for screen recording permission")) {
                            permissionService.openSystemSettings()
                        }
                        .accessibilityLabel(
                            String(
                                localized: "Open System Settings to grant screen recording permission",
                                bundle: bundle,
                                comment: "Accessibility label for the button that opens System Settings for screen recording"
                            )
                        )
                    }
                }
            } header: {
                Text(String(localized: "Permissions", bundle: bundle, comment: "Permissions section header in General settings"))
            }

            Section {
                HStack {
                    Text(String(localized: "Capture Hotkey", bundle: bundle, comment: "Capture hotkey label in General settings"))
                    Spacer()
                    HotkeyRecorderView(
                        settingsService: settingsService,
                        keyCode: Binding(
                            get: { settingsService.hotkeyKeyCode },
                            set: { settingsService.hotkeyKeyCode = $0 }
                        ),
                        modifiers: Binding(
                            get: { settingsService.hotkeyModifiers },
                            set: { settingsService.hotkeyModifiers = $0 }
                        )
                    )
                }
            } header: {
                Text(String(localized: "Hotkey", bundle: bundle, comment: "Hotkey section header in General settings"))
            }

            Section {
                Toggle(
                    String(localized: "Launch at Login", bundle: bundle, comment: "Toggle label for launch at login setting"),
                    isOn: Binding(
                        get: { loginItemService.isEnabled },
                        set: { _ in loginItemService.toggle() }
                    )
                )
            } header: {
                Text(String(localized: "Startup", bundle: bundle, comment: "Startup section header in General settings"))
            }

            Section {
                HStack {
                    Spacer()
                    Button(String(localized: "Show Onboarding Again", bundle: bundle, comment: "Button to reset and re-show the onboarding wizard")) {
                        onShowOnboarding()
                    }
                }
            } header: {
                Text(String(localized: "Onboarding", bundle: bundle, comment: "Onboarding section header in General settings"))
            }

            Section {
                Picker(
                    String(localized: "Appearance", bundle: bundle, comment: "Appearance picker label in General settings"),
                    selection: Binding(
                        get: { settingsService.appearanceMode },
                        set: { settingsService.appearanceMode = $0 }
                    )
                ) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName(bundle: bundle)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text(String(localized: "Appearance", bundle: bundle, comment: "Appearance section header in General settings"))
            }

            Section {
                Picker(
                    String(
                        localized: "Language",
                        bundle: bundle,
                        comment: "Language picker label in General settings"
                    ),
                    selection: Binding(
                        get: { settingsService.appLanguage },
                        set: { settingsService.appLanguage = $0 }
                    )
                ) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName(bundle: bundle)).tag(language)
                    }
                }
            } header: {
                Text(
                    String(
                        localized: "Language",
                        bundle: bundle,
                        comment: "Language section header in General settings"
                    )
                )
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            permissionService.checkPermission()
        }
    }
}
