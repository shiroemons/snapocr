import AppKit
import Carbon.HIToolbox
import SwiftUI

@MainActor
struct HotkeyRecorderView: View {
    let settingsService: SettingsService
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    var onHotkeyChanged: ((UInt32, UInt32) -> Void)?

    private var bundle: Bundle { settingsService.localizationBundle }

    // MARK: - Recording state

    @State private var isRecording = false
    @State private var pendingModifiers: UInt32 = 0
    // NSEvent.addLocalMonitorForEvents returns an opaque Any? token managed by AppKit.
    @State private var eventMonitor: Any?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            recordButton
            if isNonDefault {
                resetButton
            }
        }
        .onDisappear {
            cancelRecording()
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
            ? String(localized: "Recording shortcut", bundle: bundle, comment: "Accessibility label when hotkey recorder is active")
            : String(localized: "Current shortcut: \(currentDisplayString)", bundle: bundle, comment: "Accessibility label showing current hotkey")
        )
    }

    private var resetButton: some View {
        Button(String(localized: "Reset to Default", bundle: bundle, comment: "Button to restore the default hotkey")) {
            applyHotkey(keyCode: SettingsService.defaultHotkeyKeyCode, modifiers: SettingsService.defaultHotkeyModifiers)
        }
        .buttonStyle(.plain)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .accessibilityLabel(
            String(
                localized: "Reset shortcut to default",
                bundle: bundle,
                comment: "Accessibility label for the button that resets the hotkey to its default value"
            )
        )
    }

    // MARK: - Computed properties

    private var buttonLabel: String {
        if isRecording {
            if pendingModifiers != 0 {
                return KeyCodeMapping.modifierString(for: pendingModifiers)
            }
            return String(localized: "Type shortcut...", bundle: bundle, comment: "Prompt shown in hotkey recorder while waiting for key input")
        }
        return currentDisplayString
    }

    private var currentDisplayString: String {
        KeyCodeMapping.displayString(keyCode: keyCode, modifiers: modifiers)
    }

    private var isNonDefault: Bool {
        keyCode != SettingsService.defaultHotkeyKeyCode || modifiers != SettingsService.defaultHotkeyModifiers
    }

    // MARK: - Recording lifecycle

    private func toggleRecording() {
        if isRecording {
            cancelRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        removeMonitor()
        isRecording = true
        pendingModifiers = 0

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            Task { @MainActor in handleEvent(event) }
            return nil
        }
    }

    private func cancelRecording() {
        removeMonitor()
        pendingModifiers = 0
        isRecording = false
    }

    private func finishRecording() {
        removeMonitor()
        isRecording = false
    }

    private func removeMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleEvent(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            pendingModifiers = KeyCodeMapping.carbonModifiers(from: event.modifierFlags)

        case .keyDown:
            if event.keyCode == UInt16(kVK_Escape) {
                cancelRecording()
                return
            }
            let carbonMods = KeyCodeMapping.carbonModifiers(from: event.modifierFlags)
            guard carbonMods != 0 else { return }
            applyHotkey(keyCode: UInt32(event.keyCode), modifiers: carbonMods)
            finishRecording()

        default:
            break
        }
    }

    // MARK: - Apply

    private func applyHotkey(keyCode newKeyCode: UInt32, modifiers newModifiers: UInt32) {
        keyCode = newKeyCode
        modifiers = newModifiers
        onHotkeyChanged?(newKeyCode, newModifiers)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var keyCode: UInt32 = UInt32(kVK_ANSI_O)
    @Previewable @State var modifiers: UInt32 = UInt32(controlKey) | UInt32(shiftKey)

    HotkeyRecorderView(settingsService: SettingsService(), keyCode: $keyCode, modifiers: $modifiers) { newKey, newMods in
        print("Hotkey changed: \(KeyCodeMapping.displayString(keyCode: newKey, modifiers: newMods))")
    }
    .padding()
}
