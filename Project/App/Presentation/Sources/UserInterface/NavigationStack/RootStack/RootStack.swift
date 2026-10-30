
import SwiftUI

import ComposableArchitecture

struct RootStack: View {
    @State private var viewModel: ViewModel = .init()

    var body: some View {
        NavigationStack(
            path: $viewModel.paths,
            root: {
                Factory.make(
                    by: .main,
                    with: .init(
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
                )
                .navigationDestination(for: Route.self) {
                    Factory.make(
                        by: $0,
                        with: .init(
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
                    )
                }
            }
        )
        .environment(viewModel)
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
