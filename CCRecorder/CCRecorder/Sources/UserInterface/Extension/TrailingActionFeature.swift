
import SwiftUI

protocol TrailingActionFeature: View {}

extension TextField: TrailingActionFeature {}

extension SecureField: TrailingActionFeature {}

extension TrailingActionFeature {

    func trailingAction<Label: View>(
        of isPresented: Bool,
        @ViewBuilder label: @escaping () -> Label,
        action: @escaping () -> Void
    ) -> some View {
        modifier(
            TrailingActionModifier(
                isPresented: isPresented,
                label: label,
                action: action
            )
        )
    }

}

private struct TrailingActionModifier<Label: View>: ViewModifier {
    let isPresented: Bool
    let label: () -> Label
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .trailing) {
                if isPresented {
                    Button(
                        action: action,
                        label: label
                    )
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 4)
                }
            }
    }
}
