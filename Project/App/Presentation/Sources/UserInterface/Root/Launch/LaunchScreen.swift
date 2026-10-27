
import SwiftUI

enum LaunchScreen {

    struct Root: View {

        var body: some View {
            Image(asset: PresentationAsset.Launch.background)
                .resizable()
                .scaledToFill()
                .background {
                    Image(asset: PresentationAsset.Launch.background)
                        .resizable()
                        .ignoresSafeArea()
                }

        }
    }

}

#Preview {
    LaunchScreen.Root()
}
