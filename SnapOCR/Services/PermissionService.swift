import AppKit
import Observation
import os

@Observable
@MainActor
final class PermissionService: PermissionServiceProtocol {
    private static let logger = Logger(category: "PermissionService")

    private(set) var isScreenCapturePermitted = false
    private var monitorTimer: Timer?

    isolated deinit {
        monitorTimer?.invalidate()
    }

    func checkPermission() {
        let newValue = CGPreflightScreenCaptureAccess()
        if newValue != isScreenCapturePermitted {
            Self.logger.info("Screen capture permission changed: \(newValue, privacy: .public)")
            isScreenCapturePermitted = newValue
        }
    }

    /// OS のダイアログを出す。ユーザーの明示的な操作からだけ呼ぶ。
    func requestPermission() {
        CGRequestScreenCaptureAccess()
        checkPermission()
    }

    func openSystemSettings() {
        requestPermission()
        let settingsURLString =
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        guard let url = URL(string: settingsURLString) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Begins periodic permission checks every 2 seconds.
    func startMonitoring() {
        guard monitorTimer == nil else { return }
        checkPermission()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkPermission()
            }
        }
        Self.logger.info("Permission monitoring started")
    }

    /// Stops periodic permission checks and invalidates the timer.
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        Self.logger.info("Permission monitoring stopped")
    }
}
