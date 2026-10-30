
import ComposableArchitecture

extension RootStack {

    @DependencyClient
    struct Client: Sendable {
        var push: @Sendable (Route) async -> Void
        var pushContentsOf: @Sendable ([Route]) async -> Void
        var pop: @Sendable () async -> Void
        var pops: @Sendable (Int) async -> Void
        var popToRoot: @Sendable () async -> Void
        var reStack: @Sendable ([Route]) async -> Void
    }

}

extension RootStack.Client {

    static let preview: Self = .init()

}

extension DependencyValues {

    @DependencyEntry(
        previewValue: RootStack.Client.preview
    )
    var navigator: RootStack.Client = .init()

}
