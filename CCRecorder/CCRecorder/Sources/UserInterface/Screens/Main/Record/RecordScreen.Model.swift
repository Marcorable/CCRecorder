
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
    }

}

extension RecordScreen.Model {
    typealias Status = RecordScreen.Status

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

}

#if DEBUG
extension RecordScreen.Model {

    @MainActor
    static var mock: Self {
        .init(dependency: .init(recorder: MockAudioRecording()))
    }

}
#endif
