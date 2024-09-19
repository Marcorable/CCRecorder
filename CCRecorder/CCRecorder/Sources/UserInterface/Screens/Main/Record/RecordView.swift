//
//  RecordView.swift
//  CCRecorder
//
//  Created by 김용우 on 9/9/24.
//

import SwiftUI

struct RecordView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var isPresentedConfirmCancel: Bool = false
    @State private var isPresentedConfirmStop: Bool = false
    
    @State private var pins: [TimeInterval] = []
    @State private var isRecording: Bool = false
    @State private var currentTime: TimeInterval = .zero
    
    @State private var title: String = Date.now.formatted(date: .abbreviated, time: .omitted)
    @State private var topic: String = ""
    @State private var parties: [Party] = []
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .center) {
                    PinGrid(
                        pins: $pins,
                        isRecording: isRecording,
                        currentTime: currentTime
                    )
                    ConversationInfoBox(
                        title: $title,
                        topic: $topic,
                        parties: $parties
                    )
                }
                .background(Color.Light.recorder)
                .clipShape(.rect(cornerRadius: 25))
                .padding()
    //            RecordControlBoard(
    //                audioService: audioService, // TODO: 의존성주입 방식 변경 필요
    //                isPresentedConfirmStop: $isPresentedConfirmStop,
    //                pins: $pins,
    //                currentTime: currentTime,
    //                isRecording: isRecording
    //            )
            }
            .padding()
            .background(Color.Dark.recorder)
            .navigationTitle("녹음하기")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(
                        action: { isPresentedConfirmCancel.toggle() },
                        label: {
                            Text("취소")
                                .font(.headline)
                        }
                    )
                }
            }
        }
        .alert(
            "녹음 취소",
            isPresented: $isPresentedConfirmCancel,
            actions: {
                Button("삭제", role: .destructive) {
                    dismiss()
                }
                Button("취소", role: .cancel) { }
            },
            message: { Text("녹음물은 저장되지 않습니다") }
        )
        .alert(
            "녹음 완료",
            isPresented: $isPresentedConfirmStop,
            actions: {
                Button("취소", role: .cancel) { isPresentedConfirmStop.toggle() }
                Button("저장", role: .destructive) {
                    save()
                    dismiss()
                }
            },
            message: {
                Text("녹음을 중지하고 녹음물을 저장하시겠습니까?")
            }
        )
    }
    
}

private extension RecordView {
    
    func cancel() {
//        audioService.finish(isCancel: true)
    }
    
    func save() {
//        audioService.stop { result in
//            switch result {
//                case .success(let filePath):
//                    let recordedDate: Date = .init()
//                    let title: String = inputTitle.isEmpty ? recordedDate.formattedString : inputTitle
//                    
//                    let newItem: ConversationEntity = .init(
//                        id: .init(),
//                        title: title,
//                        topic: inputTopic,
//                        parties: parties.map({ $0.name }),
//                        recordFilePath: filePath,
//                        recordedDate: recordedDate,
//                        pins: pins
//                    )
//                    
//                    usecase.add(newItem) { error in
//                        guard error == nil else {
//                            print("error \(#file) \(#line)")
//                            return
//                        }
//                        // TODO: Testable Code, Have to remove
//                        print("-----> createItem filePath \n\(filePath)")
//                    }
//                case .failure(let error):
//                    print("error \(#file) \(#line)")
//            }
//            audioService.finish(isCancel: false)
//        }
    }
    
}
