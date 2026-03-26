import Testing
@testable import SnapOCR

@Suite("NotificationService Tests")
@MainActor
struct NotificationServiceTests {

    @Test func playSoundWithValidNameDoesNotCrash() {
        NotificationService.playSound(named: "Tink")
    }

    @Test func playSoundWithInvalidNameDoesNotCrash() {
        NotificationService.playSound(named: "NonexistentSound")
    }
}
