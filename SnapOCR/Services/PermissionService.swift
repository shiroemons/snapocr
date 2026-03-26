import AppKit
import os
import Observation

@Observable
@MainActor
final class PermissionService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "PermissionService")

    private(set) var isScreenCapturePermitted = false
    private var monitorTimer: Timer?

    func checkPermission() {
        let newValue = CGPreflightScreenCaptureAccess()
        if newValue != isScreenCapturePermitted {
            Self.logger.info("Screen capture permission changed: \(newValue, privacy: .public)")
            isScreenCapturePermitted = newValue
        }
    }

    func requestPermission() {
        CGRequestScreenCaptureAccess()
        checkPermission()
    }

    func openSystemSettings() {
        let settingsURLString =
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        guard let url = URL(string: settingsURLString) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func startMonitoring() {
        guard monitorTimer == nil else { return }
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermission()
            }
        }
        Self.logger.info("Permission monitoring started")
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        Self.logger.info("Permission monitoring stopped")
    }
}
