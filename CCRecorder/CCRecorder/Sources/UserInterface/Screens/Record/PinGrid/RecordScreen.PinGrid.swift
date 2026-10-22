
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
                            .foregroundStyle(circleColor)
                            .opacity(store.isRecording ? Int(store.currentTime) % 2 == 0 ? 1.0 : 0.0 : 1.0)
                        Text(store.currentTime, format: .playbackTime)
                            .foregroundStyle(timeColor)
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
                                        .foregroundStyle(Color.Logo.Prominent.red)
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

private extension RecordScreen.PinGrid {

    var circleColor: Color {
        store.isRecording ? .Logo.Prominent.red : .Logo.Muted.red
    }

    var timeColor: Color {
        store.isRecording ? .white : .gray
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
            reducer: { RecordScreen.Root.Feature() }
        )
    )
}
