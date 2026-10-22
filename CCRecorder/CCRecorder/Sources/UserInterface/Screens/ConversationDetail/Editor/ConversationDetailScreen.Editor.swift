
import Combine
import SwiftUI

extension ConversationDetailScreen {

    struct Editor: View {
        @Binding var conversation: Conversation

        @State private var title: String

        private let titleSubject: CurrentValueSubject<String, Never>
        private let topicSubject: CurrentValueSubject<String, Never>

        init(conversation: Binding<Conversation>) {
            self._conversation = conversation
            self.title = conversation.wrappedValue.title
            self.titleSubject = .init(conversation.wrappedValue.title)
            self.topicSubject = .init(conversation.wrappedValue.topic)
        }

        @FocusState private var focuseField: Field?
        @State private var isPresentedAdd: Bool = false
        @State private var isEditing: Bool = false

        var body: some View {
            VStack {
                if focuseField != .inputNote {
                    InformationBox(
                        conversation: $conversation,
                        isEditing: $isEditing,
                        focuseField: $focuseField,
                        topicSubject: topicSubject
                    )
                    .transition(.opacity)
                }
                InputBox(
                    conversation: $conversation,
                    focuseField: $focuseField
                )
                .animation(.easeOut, value: focuseField)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        HStack {
                            TextField(
                                "Title",
                                text: $title,
                                prompt: Text(conversation.createdDate.formatted(date: .abbreviated, time: .omitted))
                            )
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.roundedBorder)
                            .focused($focuseField, equals: .infoTitle)
                        }
                    } else {
                        Text(title)
                            .font(.headline)
                    }
                }
            }
            .onChange(of: title) {
                titleSubject.send($1)
            }
            .onReceive(
                titleSubject
                    .combineLatest(topicSubject)
                    .dropFirst()
                    .debounce(for: 1, scheduler: RunLoop.main)
                    .removeDuplicates { $0 == $1 }
            ) { title, topic in
                print("subject \(title) \(topic)")
                conversation.title = title
                conversation.topic = topic
            }
        }
    }

}

extension ConversationDetailScreen.Editor {

    enum Field: Hashable {
        case infoTitle
        case infoTopic
        case infoParty
        case inputNote
    }

}

#if DEBUG
#Preview {
    @Previewable @State var conversation = Conversation.preview

    NavigationStack {
        ConversationDetailScreen.Editor(conversation: $conversation)
    }
    .modelContainer(
        for: [Conversation.self, Note.self, Party.self],
        inMemory: true
    )
}
#endif
