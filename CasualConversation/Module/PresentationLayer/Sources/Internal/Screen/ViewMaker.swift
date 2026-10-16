//
//  ScreenMaker.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/07/03.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common
import Domain

import SwiftUI

final class ScreenMaker: ObservableObject {
    
	struct Dependency {
        let container: DependencyContainer
	}
	private let dependency: Dependency
    
    private var preference: Preference = .shared
	
	init(dependency: Dependency) {
		self.dependency = dependency
	}
	
}

enum Screen {
    case mainTab
    case record
    case setting
    case noteDetail(NoteEntity)
    case playTab(ConversationEntity)
    case conversationList
    case selection(ConversationEntity)
    case noteSet(NoteUsecase?) // FIXME: 필터 방식 변경 필요
}

extension ScreenMaker: ViewFactory {
    
    func makeRootView() -> AnyView {
        .init(
            makeView(.mainTab)
                .environmentObject(self)
                .accentColor(.ccAccentColor)
                .preferredColorScheme(preference.colorScheme)
        )
    }
    
}

extension ScreenMaker {
    
    func makeView(_ screen: Screen) -> some View {
        let screenView: AnyView
        let container = dependency.container
        switch screen {
            case .mainTab:
                screenView = .init(
                    MainTabView(
                        viewModel: .init()
                    )
                )
                
            case .record:
                screenView = .init(
                    RecordView(
                        usecase: container.resolve((any ConversationUsecase).self)!,
                        audioService: container.resolve(CCRecorder.self)!
                    )
                )
                
            case .setting:
                screenView = .init(
                    SettingView(
                        dependency: .init(
                            mainURL: PresentationFactory.mainURL,
                            cafeURL: PresentationFactory.cafeURL,
                            eLearningURL: PresentationFactory.eLearningURL,
                            tasteURL: PresentationFactory.tasteURL,
                            testURL: PresentationFactory.testURL,
                            receptionTel: PresentationFactory.receptionTel
                        )
                    )
                )
                
            case .noteDetail(let note):
                screenView = .init(
                    NoteDetailView(
                        item: note,
                        usecase: container.resolve(NoteUsecase.self)!
                    )
                )
                
            case .playTab(let conversation):
                let viewModel: PlayTabViewModel = .init(
                    dependency: .init(
                        item: conversation,
                        player: container.resolve(CCPlayer.self)!
                    )
                )
                screenView = .init(PlayTabView(viewModel: viewModel))
                
            case .conversationList:
                screenView = .init(
                    ConversationListView(
                        usecase: container.resolve(ConversationUsecase.self)!,
                        player: container.resolve(CCPlayer.self)!
                    )
                )
                
            case .selection(let conversation):
                screenView = .init(
                    ConversationDetailView(
                        item: conversation,
                        conversationUseCase: container.resolve(ConversationUsecase.self)!,
                        noteUsecase: container.resolve(NoteUsecase.self)!
                    )
                )
                
            case .noteSet(let usecase):
                let noteSetView: NoteSetView
                if let bindedUseCase = usecase {
                    noteSetView = .init(usecase: bindedUseCase)
                } else {
                    noteSetView = .init(usecase: container.resolve(NoteUsecase.self, name: "all")!)
                }
                screenView = .init(noteSetView)
                
        }
        
        return screenView
    }
    
}

#if DEBUG
import Combine
final class FakeConversationUsecase: ObservableObject, ConversationUsecase {
    var conversationSubejct: CurrentValueSubject<[Domain.ConversationEntity], Never> = .init([])
    func add(_ item: Domain.ConversationEntity, completion: (Common.CCError?) -> Void) {}
    func edit(after editedItem: Domain.ConversationEntity, completion: (Common.CCError?) -> Void) {}
    func delete(_ item: Domain.ConversationEntity, completion: (Common.CCError?) -> Void) {}
}

struct FakeCCRecorder: CCRecorder {
    var isRecordingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    var currentTimeSubject: CurrentValueSubject<TimeInterval, Never> = .init(.zero)
    
    func setup(completion: (Common.CCError?) -> Void) {}
    func start() {}
    func pause() {}
    func stop(completion: (Result<URL, Common.CCError>) -> Void) {}
    func finish(isCancel: Bool) {}
}

//struct FakeCCPlayer: CCPlayer {
//    var isPlayingPublisher: Published<Bool>.Publisher
//    var currentTimePublisher: Published<TimeInterval>.Publisher { .constant(.zero) }
//    var durationPublisher: Published<TimeInterval>.Publisher { .constant(10.0) }
//    
//    func stopTrackingCurrentTime() {}
//    func setupPlaying(filePath: URL, completion: (Common.CCError?) -> Void) {}
//    func startPlaying() {}
//    func pausePlaying() {}
//    func finishPlaying() {}
//    func seek(to time: Double) {}
//    func changePlayingRate(to value: Float) {}
//    func removeRecordFile(from filePath: URL, completion: (Common.CCError?) -> Void) {}
//}
#endif
