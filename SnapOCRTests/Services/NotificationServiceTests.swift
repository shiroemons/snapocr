import Foundation
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

    @Test func playSoundWithEmptyNameDoesNotCrash() {
        // Empty name produces no NSSound — service must log and return gracefully.
        NotificationService.playSound(named: "")
    }

    @Test func notifySuccessWithEmptyTextAndAllDisabled() {
        let defaults = UserDefaults(suiteName: "test.notification.allDisabled.\(UUID().uuidString)")!
        let settings = SettingsService(userDefaults: defaults)
        settings.isNotificationCenterEnabled = false
        settings.isCompletionSoundEnabled = false
        settings.isToastEnabled = false
        // All channels disabled — must complete without side effects.
        NotificationService.notifySuccess(text: "", settings: settings)
    }

    @Test func notifySuccessWithEmptyTextAndNotificationCenterEnabled() {
        let defaults = UserDefaults(suiteName: "test.notification.centerOnly.\(UUID().uuidString)")!
        let settings = SettingsService(userDefaults: defaults)
        settings.isNotificationCenterEnabled = true
        settings.isCompletionSoundEnabled = false
        settings.isToastEnabled = false
        // Empty text must be handled by the notification center path without crashing.
        NotificationService.notifySuccess(text: "", settings: settings)
    }
}
