import Testing
@testable import SnapOCR

@Suite("SnapOCR App Tests")
struct SnapOCRTests {

    @Test func appViewModelInitialState() async {
        await MainActor.run {
            let viewModel = AppViewModel()
            #expect(viewModel.isCapturing == false)
            #expect(viewModel.lastError == nil)
        }
    }
}
