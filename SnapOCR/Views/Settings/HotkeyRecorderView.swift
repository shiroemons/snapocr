import AppKit
import Carbon.HIToolbox
import SwiftUI

@MainActor
struct HotkeyRecorderView: View {
    let settingsService: SettingsService

    private var bundle: Bundle { settingsService.localizationBundle }

    // MARK: - Recording state

    @State private var isRecording = false
    @State private var pendingModifiers: UInt32 = 0
    @State private var showsInvalidShortcutHint = false
    // NSEvent.addLocalMonitorForEvents returns an opaque Any? token managed by AppKit.
    @State private var eventMonitor: Any?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                recordButton
                if isNonDefault {
                    resetButton
                }
            }
            if showsInvalidShortcutHint {
                Text(String(
                    localized: "Use a shortcut that includes ⌃, or ⌘ with another modifier.",
                    bundle: bundle,
                    comment: "Hint shown in the hotkey recorder when a key combination is rejected"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .onDisappear {
            stopRecording()
        }
        // 記録中は実際のホットキーが外れているので、別のウィンドウへ移ったまま残さない。
        // ビューを残したままウィンドウを閉じると onDisappear は来ないが、この通知は届く
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            stopRecording()
        }
    }

    // MARK: - Subviews

    private var recordButton: some View {
        Button(action: toggleRecording) {
            Text(buttonLabel)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(isRecording ? Color.accentColor : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .frame(minWidth: 90)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording
                              ? Color.accentColor.opacity(0.12)
                              : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isRecording ? Color.accentColor : Color(nsColor: .separatorColor),
                            lineWidth: isRecording ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isRecording
            ? String(
                localized: "Recording shortcut",
                bundle: bundle,
                comment: "Accessibility label when hotkey recorder is active"
            )
            : String(
                localized: "Current shortcut: \(settingsService.hotkeyDisplayString)",
                bundle: bundle,
                comment: "Accessibility label showing current hotkey"
            )
        )
    }

    private var resetButton: some View {
        Button(String(localized: "Reset to Default", bundle: bundle, comment: "Button to restore the default hotkey")) {
            applyHotkey(
                keyCode: SettingsService.defaultHotkeyKeyCode,
                modifiers: SettingsService.defaultHotkeyModifiers
            )
        }
        .buttonStyle(.plain)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .accessibilityHint(String(
            localized: "Reset shortcut to default",
            bundle: bundle,
            comment: "Accessibility hint for the button that resets the hotkey to its default value"
        ))
    }

    // MARK: - Computed properties

    private var buttonLabel: String {
        if isRecording {
            if pendingModifiers != 0 {
                return KeyCodeMapping.modifierString(for: pendingModifiers)
            }
            return String(
                localized: "Type shortcut...",
                bundle: bundle,
                comment: "Prompt shown in hotkey recorder while waiting for key input"
            )
        }
        return settingsService.hotkeyDisplayString
    }

    private var isNonDefault: Bool {
        settingsService.hotkeyKeyCode != SettingsService.defaultHotkeyKeyCode
            || settingsService.hotkeyModifiers != SettingsService.defaultHotkeyModifiers
    }

    // MARK: - Recording lifecycle

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        settingsService.isRecordingHotkey = true

        // 取消の直後に処理待ちのキーが適用されないよう、Task を挟まず同期で処理する
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            MainActor.assumeIsolated { handleEvent(event) }
            return nil
        }
    }

    /// 記録していないときは何もしない。別の場所に表示された記録中のレコーダーの状態を消さないため。
    private func stopRecording() {
        guard isRecording else { return }
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
        pendingModifiers = 0
        showsInvalidShortcutHint = false
        isRecording = false
        settingsService.isRecordingHotkey = false
    }

    private func handleEvent(_ event: NSEvent) {
        guard isRecording else { return }

        switch event.type {
        case .flagsChanged:
            pendingModifiers = KeyCodeMapping.carbonModifiers(from: event.modifierFlags)

        case .keyDown:
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return
            }
            let keyCode = UInt32(event.keyCode)
            let modifiers = KeyCodeMapping.carbonModifiers(from: event.modifierFlags)
            guard KeyCodeMapping.isValidHotkey(keyCode: keyCode, modifiers: modifiers) else {
                showsInvalidShortcutHint = true
                return
            }
            applyHotkey(keyCode: keyCode, modifiers: modifiers)

        default:
            break
        }
    }

    // MARK: - Apply

    /// キーと記録状態を同じターンで変更し、`AppViewModel` への変更通知を 1 回にまとめる。
    private func applyHotkey(keyCode: UInt32, modifiers: UInt32) {
        settingsService.hotkeyKeyCode = keyCode
        settingsService.hotkeyModifiers = modifiers
        stopRecording()
    }
}

// MARK: - Preview

#Preview {
    HotkeyRecorderView(settingsService: SettingsService())
        .padding()
}
