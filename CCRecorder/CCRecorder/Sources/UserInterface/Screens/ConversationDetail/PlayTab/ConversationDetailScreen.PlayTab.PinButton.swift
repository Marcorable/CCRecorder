
import SwiftUI

extension ConversationDetailScreen.PlayTab {

    struct PinButton: View {
        let pinDisabled: Bool
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
            .foregroundStyle(Color.Logo.Muted.blue)
            .disabled(pinDisabled)
            .opacity(pinDisabled ? 0.3 : 1.0)
        }
    }

}

#Preview {
    ConversationDetailScreen.PlayTab.PinButton(
        pinDisabled: false,
        jump: {}
    )
}
