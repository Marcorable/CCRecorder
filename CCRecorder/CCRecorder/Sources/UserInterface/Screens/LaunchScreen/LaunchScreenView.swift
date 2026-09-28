import SwiftUI

struct LaunchScreenView: View {
    @Binding var state: LaunchState
        
    var body: some View {
        Image("homex_00")
            .resizable()
            .scaledToFill()
            .background {
                Image("homex_00")
                    .resizable()
                    .ignoresSafeArea()
            }
            .task {
                await launch()
            }
    }
    
}

extension LaunchScreenView {
    
    private func launch() async {
        do {
            try AudioSessionController.configure()
        } catch {
            /// 세션 설정에 실패해도 앱은 진입시키고, 녹음 시도 시점에 다시 알린다.
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
    LaunchScreenView(state: .constant(.preprocess))
}
