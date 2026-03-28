import AppKit
import Observation
import os

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

    func requestPermissionIfNeeded() {
        checkPermission()
        guard !isScreenCapturePermitted else { return }
        Self.logger.info("Requesting screen capture access")
        requestPermission()
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
    ///
    /// Callers must ensure `stopMonitoring()` is called when monitoring is no longer needed
    /// (e.g., on view disappear or app termination) to avoid timer resource leaks.
    /// - Important: This class does not clean up the timer on deallocation because `deinit`
    ///   cannot access `@MainActor`-isolated properties. Always call `stopMonitoring()` explicitly.
    func startMonitoring() {
        guard monitorTimer == nil else { return }
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
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
