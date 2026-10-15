
import Foundation
import Testing

@testable import CCRecorder

@Suite("설정 화면 ViewModel")
@MainActor
struct SettingScreenViewModelTests {
    private let viewModel: SettingScreen.ViewModel = .mock
}

extension SettingScreenViewModelTests {

    @Test("튜토리얼 다시보기를 누르면 온보딩을 띄운다")
    func presentTutorial() {
        viewModel.reduce(by: .presentTutorial)

        #expect(viewModel.isPresentedTutorial)
    }

    @Test("온보딩을 닫으면 튜토리얼 표시를 끝낸다")
    func dismissTutorial() {
        viewModel.reduce(by: .presentTutorial)

        viewModel.reduce(by: .dismissTutorial)

        #expect(!viewModel.isPresentedTutorial)
    }

    @Test("앱 번들의 버전을 보여준다")
    func appVersion_fromBundle() {
        #expect(viewModel.appVersion == Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        #expect(viewModel.appVersion != nil)
    }

    @Test("버전 정보가 없는 번들이면 버전을 비워 둔다")
    func appVersion_missing() throws {
        let emptyBundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: emptyBundleURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: emptyBundleURL) }
        let bundle = try #require(Bundle(url: emptyBundleURL))

        let viewModel = SettingScreen.ViewModel(
            model: .init(dependency: .init(bundle: bundle))
        )

        #expect(viewModel.appVersion == nil)
    }

}
