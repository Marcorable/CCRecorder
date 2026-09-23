import SwiftUI

struct PinButton: View {
    
    let pinDisabled: Bool = false // FIXME: Player 메서드
    
    var body: some View {
        Button(
            action: { }, // skip(.next) },
            label: {
                Spacer()
                Image(systemName: "forward.end.alt.fill")
                    .font(.system(size: 16))
                Spacer()
            }
        )
        .foregroundStyle(Color.Dark.logoBlue)
        .disabled(pinDisabled)
        .opacity(pinDisabled ? 0.3 : 1.0)
    }
    
}
