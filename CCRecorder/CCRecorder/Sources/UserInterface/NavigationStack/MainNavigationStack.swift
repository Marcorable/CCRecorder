
import SwiftUI

import NavigationCoordinator

struct MainNavigationStack: View {
    @State private var path: [Screen] = []
    @State private var navigator: Navigator<Screen> = .init()

    var body: some View {
        NavigationStack(path: $path) {
            MainView()
                .navigationDestination(for: Screen.self) {
                    ScreenFactory.make(by: $0)
                }
        }
        .environment(navigator)
        .onReceive(navigator.actionPublisher, perform: action(by:))
    }
}

extension MainNavigationStack {

    private func action(by action: Navigator<Screen>.Action) {
        switch action {
            case .push(contentsOf: let screens):
                path.append(contentsOf: screens)

            case .pop(let count):
                guard count > 0 else {
                    return
                }
                path.removeLast(min(count, path.count))

            case .popToRoot:
                path.removeAll()

            case .restack(contentsOf: let screens):
                path = screens
        }
    }

}
