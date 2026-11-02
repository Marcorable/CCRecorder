
import SwiftUI

import ComposableArchitecture

struct RootStack: View {
    @AppStorage(.displayMode) private var displayMode: DisplayMode = .system

    @State private var viewModel: ViewModel = .init()
    @State private var conversationReloadID = 0

    var body: some View {
        NavigationStack(
            path: $viewModel.paths,
            root: {
                Factory.make(
                    by: .main,
                    with: client,
                    conversationReloadID: conversationReloadID
                )
                .navigationDestination(for: Route.self) { route in
                    Factory.make(
                        by: route,
                        with: client
                    )
                }
            }
        )
        .preferredColorScheme(userColorScheme)
        .environment(viewModel)
        .onChange(of: viewModel.paths) { oldValue, newValue in
            guard
                oldValue.count > newValue.count,
                case .conversationDetail? = oldValue.last
            else {
                return
            }
            conversationReloadID += 1
        }
    }

    @MainActor
    @Observable
    final class ViewModel {
        fileprivate var paths: [Route] = []

        func push(_ routes: [Route]) {
            paths.append(contentsOf: routes)
        }

        func pop(_ count: Int) {
            guard count > 0, count <= paths.count else {
                return
            }
            paths.removeLast(count)
        }

        func popToRoot() {
            paths.removeAll()
        }

        func restack(_ routes: [Route]) {
            self.paths = routes
        }
    }

}

private extension RootStack {

    var client: Client {
        .init(
            push: {
                await viewModel.push([$0])
            },
            pushContentsOf: {
                await viewModel.push($0)
            },
            pop: {
                await viewModel.pop(1)
            },
            pops: {
                await viewModel.pop($0)
            },
            popToRoot: {
                await viewModel.popToRoot()
            },
            reStack: {
                await viewModel.restack($0)
            }
        )
    }

    var userColorScheme: ColorScheme? {
        switch displayMode {
            case .system:
                nil

            case .light:
                .light

            case .dark:
                .dark
        }
    }

}
