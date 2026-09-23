import XCTest

final class CCRecorderUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// 온보딩을 건너뛴 상태로 앱을 실행한다.
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-isFirstLaunched", "NO"]
        app.launch()
        return app
    }

    /// Note 탭은 @Query / modelContext 를 사용하므로 ModelContainer 주입이 빠지면 진입 즉시 크래시한다.
    func testNoteTabDoesNotCrash() throws {
        let app = launchApp()

        let noteTab = app.buttons.element(boundBy: 2)
        XCTAssertTrue(noteTab.waitForExistence(timeout: 10), "메인 탭바가 표시되지 않음")
        noteTab.tap()

        XCTAssertTrue(app.navigationBars.buttons["더미 추가"].waitForExistence(timeout: 5),
                      "Note 탭 진입 실패 (크래시 가능성)")
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
