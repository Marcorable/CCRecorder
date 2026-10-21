
import Foundation
import Observation

extension RecordScreen {

    @MainActor
    @Observable
    final class ViewModel {
        private(set) var alert: Status.Alert?
        private(set) var isFinished: Bool = false

        @ObservationIgnored private let model: Model

        init(model: Model) {
            self.model = model
        }
    }

}

extension RecordScreen.ViewModel {

    var isRecording: Bool { model.recorder.isRecording }
    var currentTime: TimeInterval { model.recorder.currentTime }
    var pins: [TimeInterval] { model.recorder.pins }

    var isAbleToSave: Bool { currentTime > 0 }

}

extension RecordScreen.ViewModel {
    typealias Intent = RecordScreen.Intent

    func reduce(by intent: Intent) {
        switch intent {
            case .prepare:
                prepare()

            case .toggleRecording:
                isRecording
                    ? model.recorder.pause()
                    : model.recorder.start()

            case .addPin:
                model.recorder.addPin()

            case .removePin(let index):
                model.recorder.removePin(at: index)

            case .requestCancel:
                alert = .confirmCancel

            case .requestSave:
                guard isAbleToSave else {
                    return
                }
                alert = .confirmSave

            case .cancel:
                alert = nil
                model.recorder.cancel()
                isFinished = true

            case .save(let information):
                alert = nil
                save(information)

            case .dismissAlert:
                alert = nil
        }
    }

}

extension RecordScreen.ViewModel {
    typealias Status = RecordScreen.Status

    private func prepare() {
        let model = model

        Task {
            let result = await model.prepare()

            switch result {
                case .success:
                    break

                case .failure(let status):
                    update(by: status)
            }
        }
    }

    private func save(_ information: RecordScreen.Information) {
        switch model.save(information) {
            case .success:
                isFinished = true

            case .failure(let status):
                update(by: status)
        }
    }

    private func update(by status: Status) {
        alert = nil

        switch status {
            case .idle:
                break

            case .alert(let alert):
                self.alert = alert
        }
    }

}

#if DEBUG
extension RecordScreen.ViewModel {

    static var mock: RecordScreen.ViewModel {
        .init(model: .mock)
    }

}
#endif
