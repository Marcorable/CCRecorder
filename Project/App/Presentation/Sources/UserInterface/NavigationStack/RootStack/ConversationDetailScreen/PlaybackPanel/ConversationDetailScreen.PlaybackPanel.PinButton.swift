
import SwiftUI

extension ConversationDetailScreen.PlaybackPanel {

    struct PinButton: View {
        let isDisabled: Bool
        let jump: () -> Void

        var body: some View {
            Button(
                action: jump,
                label: {
                    Spacer()
                    Image(systemName: "forward.end.alt.fill")
                        .font(.system(size: 16))
                    Spacer()
                }
            )
            .foregroundStyle(Color(asset: Asset.Logo.Muted.blue))
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.3 : 1)
        }
    }

}
