import Testing
@testable import SnapOCR

@Suite("PermissionService Tests")
@MainActor
struct PermissionServiceTests {

    @Test func startMonitoringStartsTimer() {
        let service = PermissionService()
        service.startMonitoring()
        // Calling startMonitoring a second time must be idempotent (no crash, no double timer).
        service.startMonitoring()
        service.stopMonitoring()
    }

    @Test func stopMonitoringIsIdempotent() {
        let service = PermissionService()
        // Stopping without starting must not crash.
        service.stopMonitoring()
        service.stopMonitoring()
    }

    @Test func startAndStopMonitoringCycle() {
        let service = PermissionService()
        service.startMonitoring()
        service.stopMonitoring()
        // After stopping, starting again must work without issues.
        service.startMonitoring()
        service.stopMonitoring()
    }
}
