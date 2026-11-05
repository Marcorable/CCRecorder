
import Testing
import Foundation

@testable import Presentation

@Suite("공용 노트 Row 표시 값")
struct NoteBoardRowTests {}

extension NoteBoardRowTests {

    @Test("작성 완료된 노트는 원문과 번역문 및 완료 아이콘을 표시한다")
    func completedNoteShowsContentAndCompletionImage() {
        // given
        let viewModel: NoteBoard.Row.ViewModel = .init(
            id: .init(),
            original: "Apple",
            translation: "사과",
            isVocabulary: true
        )

        // when, then
        #expect(viewModel.title == "Apple")
        #expect(viewModel.subTitle == "사과")
        #expect(viewModel.noteContentImageName == "checkmark.circle.fill")
    }

    @Test("미완성 노트는 종류와 비어 있는 입력에 맞는 안내를 표시한다")
    func incompleteNoteShowsMatchingSuggestion() {
        // given
        let vocabulary: NoteBoard.Row.ViewModel = .init(
            id: .init(),
            original: "",
            translation: "사과",
            isVocabulary: true
        )
        let sentence: NoteBoard.Row.ViewModel = .init(
            id: .init(),
            original: "How are you?",
            translation: "",
            isVocabulary: false
        )

        // when, then
        #expect(vocabulary.title == "사과")
        #expect(vocabulary.subTitle == "단어를 알맞게 번역해보세요!")
        #expect(vocabulary.noteContentImageName == "k.circle")
        #expect(sentence.title == "How are you?")
        #expect(sentence.subTitle == "문장을 해석해보세요!")
        #expect(sentence.noteContentImageName == "e.circle")
    }

}
