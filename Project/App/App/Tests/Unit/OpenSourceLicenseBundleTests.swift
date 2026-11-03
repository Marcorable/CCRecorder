
import Testing
import Foundation

@testable import CCRecorder

@Suite("오픈소스 라이선스 번들")
struct OpenSourceLicenseBundleTests {}

extension OpenSourceLicenseBundleTests {

    @Test("설정 Root에는 오픈소스 라이선스 Child Pane만 있다")
    func rootContainsOnlyLicenseChildPane() throws {
        let settingsBundleURL = try settingsBundleURL()
        let root = try propertyList(at: settingsBundleURL.appending(path: "Root.plist"))
        let specifiers = try #require(root["PreferenceSpecifiers"] as? [[String: Any]])
        let childPane = try #require(specifiers.first)

        #expect(specifiers.count == 1)
        #expect(childPane["Type"] as? String == "PSChildPaneSpecifier")
        #expect(childPane["Title"] as? String == "오픈소스 라이선스")
        #expect(childPane["File"] as? String == "com.mono0926.LicensePlist")
    }

    @Test("생성된 모든 라이선스 항목은 전문 plist로 연결된다")
    func generatedItemsLinkToLicenseDetails() throws {
        let settingsBundleURL = try settingsBundleURL()
        let licenseListURL = settingsBundleURL.appending(
            path: "com.mono0926.LicensePlist.plist"
        )
        let licenseList = try propertyList(at: licenseListURL)
        let specifiers = try #require(
            licenseList["PreferenceSpecifiers"] as? [[String: Any]]
        )
        let licenseSpecifiers = specifiers.dropFirst()

        #expect(!licenseSpecifiers.isEmpty)

        for specifier in licenseSpecifiers {
            let file = try #require(specifier["File"] as? String)
            let detail = try propertyList(
                at: settingsBundleURL.appending(path: "\(file).plist")
            )
            let detailSpecifiers = try #require(
                detail["PreferenceSpecifiers"] as? [[String: Any]]
            )
            let detailSpecifier = try #require(detailSpecifiers.first)
            let licenseBody = try #require(detailSpecifier["FooterText"] as? String)

            #expect(!licenseBody.isEmpty)
        }
    }

}

private extension OpenSourceLicenseBundleTests {

    func settingsBundleURL() throws -> URL {
        try #require(
            Bundle.main.url(
                forResource: "Settings",
                withExtension: "bundle"
            )
        )
    }

    func propertyList(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        let propertyList = try PropertyListSerialization.propertyList(
            from: data,
            format: nil
        )
        return try #require(propertyList as? [String: Any])
    }

}
