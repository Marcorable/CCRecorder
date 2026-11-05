
import SwiftUI

struct LoadingProgress: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
            ProgressView()
                .tint(.white)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    Color(asset: Asset.Surface.Background.primary)
        .overlay {
            LoadingProgress()
        }
}
