
import SwiftUI

enum LaunchScreen {

    struct Root: View {

        var body: some View {
            Image(.Launch.background)
                .resizable()
                .scaledToFill()
                .background {
                    Image(.Launch.background)
                        .resizable()
                        .ignoresSafeArea()
                }

        }
    }

}

#Preview {
    LaunchScreen.Root()
}
