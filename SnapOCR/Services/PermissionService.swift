import AppKit
import Observation

@Observable
@MainActor
final class PermissionService {
    private(set) var isScreenCapturePermitted = false

    func checkPermission() {
        isScreenCapturePermitted = CGPreflightScreenCaptureAccess()
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
}
