
import SwiftUI

enum LaunchScreen {

    struct Root: View {

        var body: some View {
            Image(asset: Asset.Launch.background)
                .resizable()
                .scaledToFill()
                .background {
                    Image(asset: Asset.Launch.background)
                        .resizable()
                        .ignoresSafeArea()
                }

        }
    }

}

#Preview {
    LaunchScreen.Root()
}
