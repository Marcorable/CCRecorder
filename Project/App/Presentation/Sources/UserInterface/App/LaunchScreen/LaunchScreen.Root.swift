
import SwiftUI

enum LaunchScreen {

    struct Root: View {

        var body: some View {
            Image(asset: Asset.Launch.background)
                .resizable()
                .scaledToFill()
                .background {
                    Color(asset: Asset.Surface.Background.secondary)
                        .ignoresSafeArea()
                }
        }
    }

}

#Preview {
    LaunchScreen.Root()
}
