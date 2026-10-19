
import SwiftUI

struct ClearableTextField<Content: View>: View {
    @Binding private var text: String
    private let content: Content

    init(
        text: Binding<String>,
        @ViewBuilder content: () -> Content
    ) {
        self._text = text
        self.content = content()
    }

    var body: some View {
        content
            .overlay(alignment: .trailing) {
                ClearButton(text: $text)
                    .padding(.trailing, 4)
            }
    }
}

extension ClearableTextField {

    struct ClearButton: View {
        @Binding var text: String

        var body: some View {
            if !text.isEmpty {
                Button(
                    action: {
                        text = ""
                    },
                    label: {
                        Image(systemName: "multiply.circle.fill")
                    }
                )
                .foregroundStyle(.secondary)
                .accessibilityLabel("입력 내용 지우기")
            }
        }
    }

}
