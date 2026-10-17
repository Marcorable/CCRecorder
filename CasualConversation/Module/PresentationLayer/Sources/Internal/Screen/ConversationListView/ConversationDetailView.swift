//
//  ConversationDetailView.swift
//  Presentation
//
//  Created by Yongwoo Marco on 2022/06/23.
//

import SwiftUI
import Domain

enum ConversationDetailViewField {
    case infoTitle
    case infoTopic
    case infoMember
    case inputNote
}

struct ConversationDetailView: View {
    
	@Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject private var screenMaker: ScreenMaker
    
    let conversation: ConversationEntity
    let conversationUseCase: ConversationMaintainable
    let noteUsecase: NoteUsecase
	
	@State private var isEditing: Bool = false {
		willSet { updateEditing(by: newValue) }
	}
	@State private var isPresentedAdd: Bool = false
    
    // View Status
	@FocusState private var focusedField: ConversationDetailViewField?
    
    @State var language: Language = .original
    @State var category: Category = .sentence
    
    @State private var title: String
    @State private var topic: String
    @State private var members: String
    @State private var inputText: String = ""
    
    init(
        item: ConversationEntity,
        conversationUseCase: ConversationMaintainable,
        noteUsecase: NoteUsecase
    ) {
        self.conversation = item
        self.conversationUseCase = conversationUseCase
        self.noteUsecase = noteUsecase
        
        self._title = State(initialValue: item.title ?? "")
        self._topic = State(initialValue: item.topic ?? "")
        self._members = State(initialValue: item.members.joined(separator: ", "))
    }
	
    var body: some View {
        VStack {
            if isEditing {
                HStack {
                    TextField(
                        "Title",
                        text: $title,
                        prompt: Text(recordedDate)
                    )
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .infoTitle)
                }
            } else {
                Text(title)
                    .font(.headline)
            }
            GroupBox {
                VStack(spacing: 8) {
                    HStack {
                        Picker("Language", selection: $language) {
                            ForEach(Language.allCases, id: \.self) { condition in
                                Text(languageDescription)
                                    .tag(condition)
                            }
                        }
                        .pickerStyle(.segmented)
                        Spacer()
                        Picker("Category", selection: $category) {
                            ForEach(Category.allCases, id: \.self) { condition in
                                Text(categoryDescription)
                                    .tag(condition)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .toggleStyle(.button)
                    HStack {
                        TextField(
                            "Input Text",
                            text: $inputText,
                            prompt: Text(inputTextFieldPrompt)
                        )
                        .textFieldStyle(.roundedBorder)
                        .showClearButton($inputText)
                        .focused($focusedField, equals: .inputNote)
                        Button(
                            action: {
                                if isAbleToAdd {
                                    addNote()
                                } else {
                                    isPresentedAdd.toggle()
                                }
                            }, label: {
                                Image(systemName: "plus")
                                    .font(.headline)
                            }
                        )
                    }
                }
            }
            .padding([.leading, .trailing])
            screenMaker.makeView(.noteSet(noteUsecase))
		}
		.overlay {
            PlayTab(item: conversation)
		}
		.background(Color.ccBgColor)
		.navigationBarBackButtonHidden(true)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(
                    action: {
                        if isEditing {
                            updateEditing(by: false)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                    }
                )
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if focusedField != .inputNote {
                    GroupBox {
                        Button(
                            action: {
                                withAnimation {
                                    isEditing.toggle()
                                }
                            }, label: {
                                HStack {
                                    Text("Conversation Information")
                                        .font(.headline)
                                    Spacer()
                                    if isEditing {
                                        Text("완료")
                                    }
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.logoDarkGreen)
                                        .rotationEffect(.degrees(isEditing ? 90.0 : 0.0))
                                }
                            }
                        )
                        if isEditing {
                            VStack {
                                HStack {
                                    Text("주제")
                                        .font(.body)
                                        .fontWeight(.bold)
                                    TextField(
                                        "Topic",
                                        text: $topic,
                                        prompt: Text("주제를 입력하세요")
                                    )
                                    .textFieldStyle(.roundedBorder)
                                }
                                .focused($focusedField, equals: .infoTopic)
                                HStack {
                                    Text("참여")
                                        .font(.body)
                                        .fontWeight(.bold)
                                    TextField(
                                        "Member",
                                        text: $members,
                                        prompt: Text("참여인원을 추가하세요 (공백 분리)")
                                    )
                                    .textFieldStyle(.roundedBorder)
                                }
                                .focused($focusedField, equals: .infoMember)
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Button(
                    action: {
                        // TODO: DismissKeyboardFeature 적용
                        // dismissKeyboard()
                    }, label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                )
                Spacer()
                Button(
                    action: {
                        if isAbleToAdd {
                            addNote()
                        } else {
                            isPresentedAdd.toggle()
                        }
                    }, label: {
                        Text("추가")
                    }
                )
            }
		}
		.alert("추가 실패", isPresented: $isPresentedAdd) {
			Button("확인", role: .cancel) { }
		} message: {
			Text("올바른 조건으로 입력해주세요")
		}
	}
	
}

extension ConversationDetailView {
    
    var recordedDate: String { conversation.recordedDate.formattedString }
    var inputTextFieldPrompt: String {
        "\(languageDescription) \(categoryDescription) 입력하세요"
    }
    var languageDescription: String {
        switch language {
            case .original:      return "한글"
            case .translation:   return "영어"
        }
    }
    var categoryDescription: String {
        switch category {
            case .vocabulary:   return "단어"
            case .sentence:     return "문장"
        }
    }
    
    func addNote() {
        let newItem: NoteEntity = .init(
            id: .init(),
            original: language == .original ? self.inputText : "",
            translation: language == .translation ? self.inputText : "",
            category: category == .vocabulary ? .vocabulary : .sentence,
            references: [conversation.id],
            createdDate: Date()
        )
        noteUsecase.add(item: newItem) { error in
            guard let error = error else {
                print("add Note 실패 \(error)")
                return
            }
            self.inputText = ""
        }
    }
    
    
    
    
    var isAbleToAdd: Bool {
        checkConditions()
    }
    
    func editToggleLabel(by condition: Bool) -> String {
        condition ? "완료" : "수정"
    }
    
    private func checkConditions() -> Bool {
        guard !inputText.isEmpty else { return false }
        guard checkLanguage() else { return false }
        guard checkCategory() else { return false }
        return true
    }
    
    private func checkLanguage() -> Bool {
        switch self.language {
        case .original:        return self.inputText.range(of: "[가-힣]", options: .regularExpression) == nil
        case .translation:    return self.inputText.range(of: "[A-Za-z]", options: .regularExpression) == nil
        }
    }
    
    private func checkCategory() -> Bool {
        let spaceCount = self.inputText.trimmingCharacters(in: [" "]).components(separatedBy:  " ").count
        switch self.category {
            case .sentence:     return spaceCount > 2
            case .vocabulary:   return spaceCount < 2
        }
    }
    
    func updateEditing(by newCondition: Bool) {
        if !newCondition {
            self.updateInfo()
        }
    }
    
    private func updateInfo() {
        let beforeInfo = (
            title: conversation.title,
            topic: conversation.topic,
            memebers: conversation.members
        )
        let afterInfo = (
            title: self.title.isEmpty ? conversation.recordedDate.formattedString : title,
            topic: self.topic,
            members: self.members
                            .components(separatedBy: [",", " "] )
                            .filter({ !$0.isEmpty })
        )
        if beforeInfo != afterInfo {
            let newItem: ConversationEntity = .init(
                id: conversation.id,
                title: afterInfo.title,
                topic: afterInfo.topic,
                members: afterInfo.members,
                recordFilePath: conversation.recordFilePath,
                recordedDate: conversation.recordedDate,
                pins: conversation.pins)
            conversationUseCase.edit(after: newItem) { error in
                guard error == nil else {
                    print("\(error)")
                    return
                }
            }
        }
    }
}

fileprivate struct PlayTab: View {
    let item: ConversationEntity
    @EnvironmentObject private var screenMaker: ScreenMaker
    
    var body: some View {
        VStack {
            Spacer()
            screenMaker.makeView(.playTab(item))
        }
    }
    
}




//#if DEBUG // MARK: - Preview
//struct SelectionView_Previews: PreviewProvider {
//	
//	static var container: PresentationDIContainer { .preview }
//	
//	static var previews: some View {
//		container.SelectionView(selected: .empty)
//			.environmentObject(container)
//			.preferredColorScheme(.light)
//		container.SelectionView(selected: .empty)
//			.environmentObject(container)
//			.preferredColorScheme(.dark)
//	}
//
//}
//#endif
