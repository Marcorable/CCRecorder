
import SwiftUI

import ComposableArchitecture

extension RecordScreen {

    struct PinGrid: View {
        let store: StoreOf<Root.Feature>

        var body: some View {
            ScrollView(
                .vertical,
                showsIndicators: true
            ) {
                LazyVStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Image(systemName: "circle.fill")
                            .foregroundStyle(
                                Color(
                                    asset: store.isRecording
                                    ? Asset.Logo.Prominent.red
                                    : Asset.Logo.Muted.red
                                )
                            )
                            .opacity(store.isRecordingIndicatorVisible ? 1 : 0)
                        Text(store.currentTime, format: .playbackTime)
                            .foregroundStyle(store.isRecording ? .white : .gray)
                            .font(.largeTitle)
                        Spacer()
                    }
                    .padding(.vertical, 30)

                    ForEach(store.pins.indices, id: \.self) { index in
                        HStack {
                            HStack(spacing: 4) {
                                Text("📌")
                                Text(store.pins[index], format: .playbackTime)
                            }
                            Spacer()
                            Button(
                                action: {
                                    withAnimation {
                                        _ = store.send(.view(.removePinButtonTapped(index)))
                                    }
                                },
                                label: {
                                    Image(systemName: "delete.backward")
                                        .foregroundStyle(
                                            Color(asset: Asset.Logo.Prominent.red)
                                        )
                                }
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)

                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
    }

}

#Preview {
    RecordScreen.PinGrid(
        store: .init(
            initialState: .init(
                phase: .recording,
                currentTime: 3,
                pins: [3.0, 2.1]
            ),
            reducer: {
                RecordScreen.Root.Feature()
            }
        )
    )
}
