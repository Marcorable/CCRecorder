
import SwiftUI

extension LaunchScreen {

    struct Context: View {
        @Environment(\.modelContext) private var modelContext
        @Binding var state: LaunchState

        var body: some View {
            Image(.Launch.background)
                .resizable()
                .scaledToFill()
                .background {
                    Image(.Launch.background)
                        .resizable()
                        .ignoresSafeArea()
                }
                .task {
                    await launch()
                }
        }
    }

}

extension LaunchScreen.Context {

    private func launch() async {
        do {
            try AudioSessionController.configure()
        } catch {
            /// 세션 설정에 실패해도 앱은 진입시키고, 녹음 시도 시점에 다시 알린다.
            print("\(Self.self) \(#function) - \(error)")
        }

        do {
            _ = try LegacyStoreMigrator().migrateIfNeeded(into: modelContext)
        } catch {
            print("\(Self.self) \(#function) - \(error)")
        }

        do {
            try await Task.sleep(for: .seconds(2)) // FIXME: Launch Process

            state = .launched
        } catch {

        }
    }

}

#Preview {
    LaunchScreen.Context(state: .constant(.preprocess))
}
