//
//  GeneralSettingsView.swift
//  SnapOCR
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
            Section(String(
                localized: "Permissions",
                bundle: bundle,
                comment: "Permissions section header in General settings"
            )) {
                HStack {
                    Image(systemName: permissionService.isScreenCapturePermitted
                          ? "checkmark.circle.fill"
                          : "exclamationmark.triangle.fill")
                        .foregroundStyle(permissionService.isScreenCapturePermitted ? .green : .orange)
                        .accessibilityHidden(true)
                    Text(
                        permissionService.isScreenCapturePermitted
                            ? String(
                                localized: "Screen Recording: Allowed",
                                bundle: bundle,
                                comment: "Screen recording permission granted status"
                            )
                            : String(
                                localized: "Screen Recording: Not Allowed",
                                bundle: bundle,
                                comment: "Screen recording permission denied status"
                            )
                    )
                    Spacer()
                    if !permissionService.isScreenCapturePermitted {
                        Button(String(
                            localized: "Open System Settings",
                            bundle: bundle,
                            comment: "Button to open System Settings for screen recording permission"
                        )) {
                            permissionService.openSystemSettings()
                        }
                        .accessibilityHint(String(
                            localized: "Open System Settings to grant screen recording permission",
                            bundle: bundle,
                            comment: "Accessibility hint for the button that opens System Settings for screen recording"
                        ))
                    }
                }
            }

            Section(String(
                localized: "General",
                bundle: bundle,
                comment: "General section header in General settings"
            )) {
                HStack {
                    Text(String(
                        localized: "Capture Hotkey",
                        bundle: bundle,
                        comment: "Capture hotkey label in General settings"
                    ))
                    Spacer()
                    HotkeyRecorderView(settingsService: settingsService)
                }
                Toggle(
                    String(
                        localized: "Launch at Login",
                        bundle: bundle,
                        comment: "Toggle label for launch at login setting"
                    ),
                    isOn: Binding(
                        get: { loginItemService.isEnabled },
                        set: { loginItemService.setEnabled($0) }
                    )
                )
                if loginItemService.requiresApproval {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        Text(String(
                            localized: "Allow SnapOCR in System Settings to launch it at login.",
                            bundle: bundle,
                            comment: "Shown when the login item needs approval in System Settings"
                        ))
                        Spacer()
                        Button(String(
                            localized: "Open System Settings",
                            bundle: bundle,
                            comment: "Button to open System Settings for approving the login item"
                        )) {
                            loginItemService.openSystemSettings()
                        }
                    }
                }
                Picker(
                    String(
                        localized: "Appearance",
                        bundle: bundle,
                        comment: "Appearance picker label in General settings"
                    ),
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
                Picker(
                    String(localized: "Language", bundle: bundle, comment: "Language picker label in General settings"),
                    selection: Binding(
                        get: { settingsService.appLanguage },
                        set: { settingsService.appLanguage = $0 }
                    )
                ) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName(bundle: bundle)).tag(language)
                    }
                }
            }

            Section(String(
                localized: "Onboarding",
                bundle: bundle,
                comment: "Onboarding section header in General settings"
            )) {
                HStack {
                    Spacer()
                    Button(
                        String(
                            localized: "Show Onboarding Again",
                            bundle: bundle,
                            comment: "Button to reset and re-show the onboarding wizard"
                        ),
                        action: onShowOnboarding
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            permissionService.checkPermission()
            loginItemService.refresh()
        }
    }
}
