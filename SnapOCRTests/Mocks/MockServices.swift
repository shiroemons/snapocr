import CoreGraphics
import Foundation
import ServiceManagement
@testable import SnapOCR

// MARK: - MockOCRService

@MainActor
final class MockOCRService: OCRServiceProtocol {
    var recognizeTextResult = "Mocked OCR text"
    var recognizeTextError: (any Error)?
    private(set) var recognizeTextCallCount = 0
    private(set) var lastRecognizeImage: CGImage?
    private(set) var lastRecognizeLanguages: [String]?

    func recognizeText(from image: CGImage, languages: [String]) async throws -> String {
        recognizeTextCallCount += 1
        lastRecognizeImage = image
        lastRecognizeLanguages = languages
        if let recognizeTextError { throw recognizeTextError }
        return recognizeTextResult
    }
}

// MARK: - MockCaptureService

@MainActor
final class MockCaptureService: CaptureServiceProtocol {
    struct Arguments: Equatable {
        let rect: CGRect
        let displayID: CGDirectDisplayID
        let screenSize: CGSize
        let scaleFactor: CGFloat
    }

    var captureRegionResult = makeDummyImage()
    var captureRegionError: (any Error)?
    private(set) var captureRegionCallCount = 0
    private(set) var lastArguments: Arguments?

    func captureRegion(
        _ rect: CGRect,
        displayID: CGDirectDisplayID,
        screenSize: CGSize,
        scaleFactor: CGFloat
    ) async throws -> CGImage {
        captureRegionCallCount += 1
        lastArguments = Arguments(rect: rect, displayID: displayID, screenSize: screenSize, scaleFactor: scaleFactor)
        if let captureRegionError { throw captureRegionError }
        return captureRegionResult
    }
}

private func makeDummyImage() -> CGImage {
    guard let context = CGContext(
        data: nil, width: 1, height: 1,
        bitsPerComponent: 8, bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ), let image = context.makeImage() else {
        fatalError("Failed to create 1x1 dummy CGImage for testing")
    }
    return image
}

// MARK: - MockClipboardService

@MainActor
final class MockClipboardService: ClipboardServiceProtocol {
    var copyResult = true
    private(set) var copyCallCount = 0
    private(set) var lastCopiedText: String?

    func copy(_ text: String) -> Bool {
        copyCallCount += 1
        // 本番の ClipboardService と同じく、空文字はコピーしない
        guard !text.isEmpty else { return false }
        lastCopiedText = text
        return copyResult
    }
}

// MARK: - MockNotificationService

@MainActor
final class MockNotificationService: NotificationServiceProtocol {
    private(set) var notifySuccessCallCount = 0
    private(set) var lastNotifiedText: String?
    private(set) var failureMessages: [String] = []

    func notifySuccess(text: String, settings: SettingsService) {
        notifySuccessCallCount += 1
        lastNotifiedText = text
    }

    func notifyFailure(message: String) {
        failureMessages.append(message)
    }
}

// MARK: - MockRegionSelector

@MainActor
final class MockRegionSelector: RegionSelectorProtocol {
    var selectRegionResult: SelectionResult?
    /// true の間は `finishSelection(with:)` が呼ばれるまで範囲選択を終えない。キャプチャの実行中を作るために使う。
    var suspendsSelection = false
    private(set) var selectRegionCallCount = 0
    private var continuation: CheckedContinuation<SelectionResult?, Never>?

    var isWaitingForSelection: Bool { continuation != nil }

    func selectRegion() async -> SelectionResult? {
        selectRegionCallCount += 1
        guard suspendsSelection else { return selectRegionResult }
        return await withCheckedContinuation { continuation = $0 }
    }

    func finishSelection(with result: SelectionResult?) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}

// MARK: - MockPermissionService

@MainActor
final class MockPermissionService: PermissionServiceProtocol {
    var isScreenCapturePermitted = true
    private(set) var openSystemSettingsCallCount = 0

    func checkPermission() {}

    func openSystemSettings() {
        openSystemSettingsCallCount += 1
    }
}

// MARK: - MockHotkeyService

@MainActor
final class MockHotkeyService: HotkeyServiceProtocol {
    struct Registration: Equatable {
        let keyCode: UInt32
        let modifiers: UInt32
    }

    var onHotkeyPressed: (@MainActor () -> Void)?
    /// 登録に失敗させるキー。本番と同じく、失敗しても旧キーの登録は残る。
    var rejectedKeyCodes: Set<UInt32> = []
    private(set) var keyCode = SettingsService.defaultHotkeyKeyCode
    private(set) var modifiers = SettingsService.defaultHotkeyModifiers
    private(set) var isRegistered = false
    private(set) var registrations: [Registration] = []
    private(set) var unregisterCallCount = 0

    func updateHotkey(keyCode newKeyCode: UInt32, modifiers newModifiers: UInt32) -> Bool {
        registrations.append(Registration(keyCode: newKeyCode, modifiers: newModifiers))
        guard !rejectedKeyCodes.contains(newKeyCode) else { return false }
        keyCode = newKeyCode
        modifiers = newModifiers
        isRegistered = true
        return true
    }

    func unregister() {
        unregisterCallCount += 1
        isRegistered = false
    }
}

// MARK: - MockLoginItemRegistering

@MainActor
final class MockLoginItemRegistering: LoginItemRegistering {
    var status: SMAppService.Status
    /// 登録に成功した後の状態。ユーザーの許可待ちを再現するときに `.requiresApproval` を入れる。
    var statusAfterRegister = SMAppService.Status.enabled
    var registerError: (any Error)?
    var unregisterError: (any Error)?
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0

    init(status: SMAppService.Status = .notRegistered) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        if let registerError { throw registerError }
        status = statusAfterRegister
    }

    func unregister() throws {
        unregisterCallCount += 1
        if let unregisterError { throw unregisterError }
        status = .notRegistered
    }
}
