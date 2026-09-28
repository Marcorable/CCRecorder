import SwiftUI

struct SettingView: View {
    @Environment(ViewCoordinator.self) private var viewCoordinator
    
    var body: some View {
        Button(
            action: { viewCoordinator.pop() },
            label: { Text("pop") }
        )
        .navigationTitle("설정화면")
    }
}

#Preview {
    SettingView()
        .environment(ViewCoordinator())
}
