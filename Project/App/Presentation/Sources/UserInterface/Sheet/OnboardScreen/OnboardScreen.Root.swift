
import SwiftUI

import ComposableArchitecture

enum OnboardScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        private let pages: [PresentationImages] = [
            Asset.Onboarding.page0,
            Asset.Onboarding.page1,
            Asset.Onboarding.page2,
            Asset.Onboarding.page3,
            Asset.Onboarding.page4
        ]

        var body: some View {
            TabView {
                ForEach(pages.indices, id: \.self) { index in
                    Image(asset: pages[index])
                        .resizable()
                        .scaledToFit()
                        .overlay(alignment: .bottom) {
                            if index == pages.count - 1 {
                                Button(
                                    action: {
                                        store.send(.view(.startButtonTapped))
                                    },
                                    label: {
                                        Text("앱 시작하기")
                                            .tint(.white)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .padding()
                                            .background(Color(asset: Asset.Icon.accent))
                                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                                    }
                                )
                                .clipShape(.rect(cornerRadius: 15))
                                .padding(40)
                            }
                        }
                        .clipShape(.rect(cornerRadius: 50))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .background(Color(asset: Asset.Surface.Recorder.prominent))
        }
    }

}

#Preview {
    OnboardScreen.Root(
        store: .init(
            initialState: .init(),
            reducer: { OnboardScreen.Root.Feature() }
        )
    )
}
