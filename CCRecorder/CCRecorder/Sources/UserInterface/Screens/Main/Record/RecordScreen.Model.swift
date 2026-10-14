
import Foundation
import SwiftData

extension RecordScreen {

    struct Model {
        private let dependency: Dependency

        init(dependency: Dependency) {
            self.dependency = dependency
        }
    }

}

extension RecordScreen.Model {

    struct Dependency {
        let recorder: any AudioRecording
        let modelContext: ModelContext
        let fileStore: RecordFileStore
    }

}

extension RecordScreen.Model {
    typealias Status = RecordScreen.Status
    typealias Information = RecordScreen.Information

    var recorder: any AudioRecording { dependency.recorder }

    @MainActor
    func prepare() async -> Result<Void, Status> {
        do {
            try await recorder.prepare()
            return .success(())
        } catch AudioRecorder.RecordError.permissionDenied {
            return .failure(.alert(.permissionDenied))
        } catch is CancellationError {
            return .failure(.idle)
        } catch {
            return .failure(.alert(.prepareFailed))
        }
    }

    /// 녹음을 끝내고 대화로 저장한다. 저장하지 못하면 녹음 파일도 남기지 않는다.
    @MainActor
    func save(_ information: Information) -> Result<Void, Status> {
        let pins = recorder.pins
        let recordFilePath: URL

        do {
            recordFilePath = try recorder.finish()
        } catch {
            return .failure(.alert(.saveFailed))
        }

        let createdDate = Date.now
        let title = information.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let conversation = Conversation(
            createdDate: createdDate,
            recordFilePath: recordFilePath,
            pins: pins,
            title: title.isEmpty ? RecordScreen.defaultTitle(of: createdDate) : title,
            topic: information.topic,
            parties: information.parties.map { Party(name: $0) }
        )

        do {
            dependency.modelContext.insert(conversation)
            try dependency.modelContext.save()
            return .success(())
        } catch {
            dependency.modelContext.rollback()
            try? dependency.fileStore.removeFile(at: recordFilePath)
            return .failure(.alert(.saveFailed))
        }
    }

}

#if DEBUG
extension RecordScreen.Model {

    @MainActor
    static var mock: Self {
        .init(
            dependency: .init(
                recorder: MockAudioRecording(),
                modelContext: .mock,
                fileStore: .init()
            )
        )
    }

}

extension ModelContext {

    /// 메모리에만 저장하는 컨텍스트. 프리뷰와 테스트에서 쓴다.
    static var mock: ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Conversation.self, Note.self, Party.self,
            configurations: configuration
        )
        return .init(container)
    }

}
#endif
