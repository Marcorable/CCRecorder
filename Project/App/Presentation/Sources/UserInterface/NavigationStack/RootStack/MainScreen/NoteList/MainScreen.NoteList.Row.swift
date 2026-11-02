
import SwiftUI
import Foundation

extension MainScreen.NoteList {

    struct Row: View {
        let viewModel: ViewModel

        var body: some View {
            HStack {
                Image(systemName: viewModel.categoryImageName)
                    .foregroundStyle(Color(asset: Asset.Logo.Prominent.red))
                    .frame(
                        width: 36,
                        alignment: .center
                    )
                VStack(alignment: .leading) {
                    if viewModel.isDone {
                        Text(viewModel.original)
                        Text(viewModel.translation)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        Text(viewModel.noteContentLabel)
                        Text(viewModel.suggestLabel)
                            .font(.caption)
                            .foregroundStyle(Color(asset: Asset.Icon.accent))
                    }
                }
                Spacer()
                Image(systemName: viewModel.noteContentImageName)
                    .foregroundStyle(viewModel.noteContentColor)
            }
            .font(.body)
            .listRowBackground(Color.clear)
            .contentShape(.rect)
        }
    }

}

extension MainScreen.NoteList.Row {

    struct ViewModel: Equatable, Identifiable {
        let id: UUID
        let original: String
        let translation: String
        let isVocabulary: Bool

        var isDone: Bool { !original.isEmpty && !translation.isEmpty }
        var categoryImageName: String { isVocabulary ? "textformat.abc" : "text.bubble.fill" }
        var noteContentLabel: String { original.isEmpty ? translation : original }

        var noteContentImageName: String {
            if isDone {
                "checkmark.circle.fill"
            } else {
                original.isEmpty ? "k.circle" : "e.circle"
            }
        }

        var noteContentColor: Color {
            isDone
                ? Color(asset: Asset.Logo.Prominent.blue)
                : Color(asset: Asset.Logo.Muted.blue)
        }

        var suggestLabel: String {
            if isVocabulary {
                original.isEmpty ? "단어를 알맞게 번역해보세요!" : "단어의 뜻을 찾아보세요!"
            } else {
                original.isEmpty ? "문장을 번역해보세요!" : "문장을 해석해보세요!"
            }
        }
    }

}
