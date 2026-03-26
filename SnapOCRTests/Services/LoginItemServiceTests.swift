import Testing
@testable import SnapOCR

@Suite("LoginItemService Tests")
@MainActor
struct LoginItemServiceTests {
    @Test func isEnabledReturnsBoolValue() {
        let service = LoginItemService()
        // Just verify it returns a Bool without crashing
        let _ = service.isEnabled
    }

    @Test func isEnabledIsConsistentWithoutSideEffects() {
        let service = LoginItemService()
        let first = service.isEnabled
        let second = service.isEnabled
        #expect(first == second, "isEnabled must return a consistent value when called without intervening mutations")
    }

    @Test func enableDoesNotThrow() {
        let service = LoginItemService()
        service.enable()
        // Cleanup: disable to restore state
        service.disable()
    }

    @Test func disableDoesNotThrow() {
        let service = LoginItemService()
        service.disable()
    }

    @Test func toggleDoesNotThrow() {
        let service = LoginItemService()
        let initial = service.isEnabled
        service.toggle()
        // Restore original state
        if service.isEnabled != initial {
            service.toggle()
        }
    }
}
