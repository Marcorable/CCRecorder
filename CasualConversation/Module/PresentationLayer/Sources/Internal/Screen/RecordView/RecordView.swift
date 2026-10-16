//
//  RecordView.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/23.
//

import Domain

import SwiftUI
import Combine

struct RecordView: View, DismissKeyboardFeature {
    
    @Environment(\.presentationMode) private var presentationMode
    
    let usecase: ConversationRecodable
    let audioService: CCRecorder
    
    @State var isRecording: Bool = false
    @State var isPrepared: Bool = false
    
    @State var inputTitle: String = Date().formattedString
    @State var inputTopic: String = ""
    @State var inputMember: String = ""
    @State var members: [Member] = []
    @State var pins: [TimeInterval] = []
    
    @State var currentTime: TimeInterval = .zero
    @State var recordingTime: TimeInterval = .zero
    
    @State private var isPresentedConfirmCancel: Bool = false
    @State private var isPresentedConfirmStop: Bool = false
    
    var body: some View {
        content
            .onAppear {
                audioService.setup { error in
                    guard error == nil else { // MARK: - 실기기만 동작 가능
                        print("error \(#file) \(#line)")
                        return
                    }
                    isPrepared = true
                    pins = []
                    members = []
                }
            }
            .onDisappear {
                self.isPrepared = false
                self.members = []
                self.pins = []
                
                dismissKeyboard()
            }
            .onReceive(audioService.isRecordingSubject) {isRecording in
                self.isRecording = isRecording
            }
            .onReceive(audioService.currentTimeSubject) { currentTime in
                self.currentTime = currentTime
            }
            .alert(
                "녹음 취소",
                isPresented: $isPresentedConfirmCancel,
                actions: {
                    Button("삭제", role: .destructive) {
                        audioService.finish(isCancel: true)
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("취소", role: .cancel) { }
                },
                message: { Text("녹음물은 저장되지 않습니다") }
            )
            .alert(
                "녹음 완료",
                isPresented: $isPresentedConfirmStop,
                actions: {
                    Button("취소", role: .cancel) { }
                    Button("저장") {
                        audioService.stop { result in
                            switch result {
                                case .success(let filePath):
                                    let recordedDate: Date = .init()
                                    let title: String = inputTitle.isEmpty ? recordedDate.formattedString : inputTitle
                                    
                                    let newItem: ConversationEntity = .init(
                                        id: .init(),
                                        title: title,
                                        topic: inputTopic,
                                        members: members.map({ $0.name }),
                                        recordFilePath: filePath,
                                        recordedDate: recordedDate,
                                        pins: pins
                                    )
                                    
                                    usecase.add(newItem) { error in
                                        guard error == nil else {
                                            print("error \(#file) \(#line)")
                                            return
                                        }
                                        // TODO: Testable Code, Have to remove
                                        print("-----> createItem filePath \n\(filePath)")
                                    }
                                case .failure(let error):
                                    print("error \(#file) \(#line)")
                            }
                            audioService.finish(isCancel: false)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                message: {
                    Text("녹음을 중지하고 녹음물을 저장하시겠습니까?")
                }
            )
    }
    
    var content: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .center) {
                    PinGrid(
                        pins: $pins,
                        isRecording: isRecording,
                        currentTime: currentTime
                    )
                    ConversationInfo(
                        inputTitle: $inputTitle,
                        inputTopic: $inputTopic,
                        inputMember: $inputMember,
                        members: $members
                    )
                    
                }
                .background(
                    Color.lightRecordColor
                        .cornerRadius(25)
                )
                .padding()
                RecordControlBoard(
                    audioService: audioService, // TODO: 의존성주입 방식 변경 필요
                    isPresentedConfirmStop: $isPresentedConfirmStop,
                    pins: $pins,
                    currentTime: currentTime,
                    isRecording: isRecording
                )
            }
            .padding()
            .background(Color.darkRecordColor)
            .navigationTitle("Casual Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(
                RecordViewToolBar(
                    cancelAction: { isPresentedConfirmCancel.toggle() }
                )
            )
        }
        .preferredColorScheme(.dark)
    }
    
}

//#if DEBUG // MARK: - Preview
//struct RecordView_Previews: PreviewProvider {
//
//	static var container: PresentationDIContainer { .preview }
//
//	static var previews: some View {
//		container.recordView()
//	}
//
//}
//#endif
