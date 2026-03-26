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

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: permissionService.isScreenCapturePermitted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(permissionService.isScreenCapturePermitted ? .green : .yellow)
                        .accessibilityHidden(true)
                    Text(
                        permissionService.isScreenCapturePermitted
                            ? String(localized: "Screen Recording: Allowed", comment: "Screen recording permission granted status")
                            : String(localized: "Screen Recording: Not Allowed", comment: "Screen recording permission denied status")
                    )
                    Spacer()
                    if !permissionService.isScreenCapturePermitted {
                        Button(String(localized: "Open System Settings", comment: "Button to open System Settings for screen recording permission")) {
                            permissionService.openSystemSettings()
                        }
                        .accessibilityLabel(
                            String(
                                localized: "Open System Settings to grant screen recording permission",
                                comment: "Accessibility label for the button that opens System Settings for screen recording"
                            )
                        )
                    }
                }
            } header: {
                Text(String(localized: "Permissions", comment: "Permissions section header in General settings"))
            }

            Section {
                HStack {
                    Text(String(localized: "Capture Hotkey", comment: "Capture hotkey label in General settings"))
                    Spacer()
                    HotkeyRecorderView(
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
                Text(String(localized: "Hotkey", comment: "Hotkey section header in General settings"))
            }

            Section {
                Toggle(
                    String(localized: "Launch at Login", comment: "Toggle label for launch at login setting"),
                    isOn: Binding(
                        get: { loginItemService.isEnabled },
                        set: { _ in loginItemService.toggle() }
                    )
                )
            } header: {
                Text(String(localized: "Startup", comment: "Startup section header in General settings"))
            }

            Section {
                HStack {
                    Spacer()
                    Button(String(localized: "Show Onboarding Again", comment: "Button to reset and re-show the onboarding wizard")) {
                        onShowOnboarding()
                    }
                }
            } header: {
                Text(String(localized: "Onboarding", comment: "Onboarding section header in General settings"))
            }

            Section {
                Picker(
                    String(localized: "Appearance", comment: "Appearance picker label in General settings"),
                    selection: Binding(
                        get: { settingsService.appearanceMode },
                        set: { settingsService.appearanceMode = $0 }
                    )
                ) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text(String(localized: "Appearance", comment: "Appearance section header in General settings"))
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            permissionService.checkPermission()
        }
    }
}
