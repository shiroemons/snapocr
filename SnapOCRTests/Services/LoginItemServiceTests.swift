import ServiceManagement
@testable import SnapOCR
import Testing

@Suite("LoginItemService Tests")
@MainActor
struct LoginItemServiceTests {
    private struct RegistrationFailure: Error {}

    // MARK: - Status

    @Test func statusIsReadFromAppServiceAtInit() {
        let service = LoginItemService(appService: MockLoginItemRegistering(status: .enabled))
        #expect(service.status == .enabled)
        #expect(service.isEnabled)
        #expect(!service.requiresApproval)
    }

    @Test func requiresApprovalIsTrueOnlyWhileWaitingForApproval() {
        let waiting = LoginItemService(appService: MockLoginItemRegistering(status: .requiresApproval))
        #expect(waiting.requiresApproval)
        #expect(!waiting.isEnabled)

        let notRegistered = LoginItemService(appService: MockLoginItemRegistering(status: .notRegistered))
        #expect(!notRegistered.requiresApproval)
        #expect(!notRegistered.isEnabled)
    }

    @Test func refreshPicksUpChangesMadeInSystemSettings() {
        let appService = MockLoginItemRegistering(status: .requiresApproval)
        let service = LoginItemService(appService: appService)

        appService.status = .enabled
        #expect(service.status == .requiresApproval)

        service.refresh()
        #expect(service.status == .enabled)
    }

    // MARK: - setEnabled

    @Test func enablingRegistersAndUpdatesStatus() {
        let appService = MockLoginItemRegistering(status: .notRegistered)
        let service = LoginItemService(appService: appService)

        #expect(service.setEnabled(true))

        #expect(appService.registerCallCount == 1)
        #expect(appService.unregisterCallCount == 0)
        #expect(service.status == .enabled)
    }

    @Test func disablingUnregistersAndUpdatesStatus() {
        let appService = MockLoginItemRegistering(status: .enabled)
        let service = LoginItemService(appService: appService)

        #expect(service.setEnabled(false))

        #expect(appService.unregisterCallCount == 1)
        #expect(appService.registerCallCount == 0)
        #expect(service.status == .notRegistered)
    }

    @Test func enablingCanEndUpWaitingForApproval() {
        let appService = MockLoginItemRegistering(status: .notRegistered)
        appService.statusAfterRegister = .requiresApproval
        let service = LoginItemService(appService: appService)

        #expect(service.setEnabled(true))

        #expect(service.requiresApproval)
        #expect(!service.isEnabled)
    }

    @Test func failedEnableReturnsFalseAndKeepsStatus() {
        let appService = MockLoginItemRegistering(status: .notRegistered)
        appService.registerError = RegistrationFailure()
        let service = LoginItemService(appService: appService)

        #expect(service.setEnabled(true) == false)

        #expect(service.status == .notRegistered)
    }

    @Test func failedDisableReturnsFalseAndKeepsStatus() {
        let appService = MockLoginItemRegistering(status: .enabled)
        appService.unregisterError = RegistrationFailure()
        let service = LoginItemService(appService: appService)

        #expect(service.setEnabled(false) == false)

        #expect(service.status == .enabled)
    }

    @Test func failedEnableStillPicksUpActualStatus() {
        let appService = MockLoginItemRegistering(status: .notRegistered)
        appService.registerError = RegistrationFailure()
        let service = LoginItemService(appService: appService)
        appService.status = .requiresApproval

        #expect(service.setEnabled(true) == false)

        #expect(service.status == .requiresApproval)
    }
}
