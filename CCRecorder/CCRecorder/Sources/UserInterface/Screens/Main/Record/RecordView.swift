
import SwiftUI

struct RecordView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var isPresentedConfirmCancel: Bool = false
    @State private var isPresentedConfirmStop: Bool = false
    
    @State private var recorder = AudioRecorder()
    
    @State private var title: String = Date.now.formatted(date: .abbreviated, time: .omitted)
    @State private var topic: String = ""
    @State private var parties: [Party] = []
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .center) {
                    PinGrid(
                        pins: recorder.pins,
                        isRecording: recorder.isRecording,
                        currentTime: recorder.currentTime,
                        delete: recorder.removePin(at:)
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
                ControlBoard(
                    recorder: recorder,
                    isPresentedConfirmStop: $isPresentedConfirmStop
                )
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
        .task {
            // 임시: 준비 실패 안내는 #28 에서 붙인다
            try? await recorder.prepare()
        }
        .alert(
            "녹음 취소",
            isPresented: $isPresentedConfirmCancel,
            actions: {
                Button("삭제", role: .destructive) {
                    cancel()
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
        recorder.cancel()
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
