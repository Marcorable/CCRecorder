
import AVFAudio

import Domain

@MainActor
final class RecorderService {
    private var state: State = .idle
    private var pausedTime: TimeInterval = .zero
    private var recorder: AVAudioRecorder?

    var isRecording: Bool {
        state == .recording
    }

    var currentTime: TimeInterval {
        guard state == .recording, let recorder else {
            return pausedTime
        }
        return recorder.currentTime
    }

    init() {}
}

extension RecorderService {

    enum State {
        case idle
        case recording
        case paused
    }

    enum ServiceError: Error {
        case prepareFailed
        case notPrepared
    }

}

extension RecorderService: RecorderServiceInterface {

    func prepare(with fileURL: URL) throws {
        do {
            let recorder = try AVAudioRecorder(
                url: fileURL,
                settings: [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
            )

            guard recorder.prepareToRecord() else {
                throw ServiceError.prepareFailed
            }

            self.recorder = recorder
            self.state = .idle
            self.pausedTime = .zero
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.prepareFailed
        }
    }

    func start() {
        guard
            let recorder,
            state != .recording,
            recorder.record()
        else {
            return
        }

        state = .recording
    }

    func pause() {
        guard state == .recording, let recorder else {
            return
        }

        pausedTime = recorder.currentTime
        recorder.pause()
        state = .paused
    }

    func finish() throws -> URL {
        guard let recorder else {
            throw ServiceError.notPrepared
        }

        let fileURL = recorder.url
        pausedTime = recorder.currentTime
        recorder.stop()
        cleanUp()

        return fileURL
    }

    func cancel() {
        recorder?.stop()
        cleanUp()
        pausedTime = .zero
    }

}

private extension RecorderService {

    func cleanUp() {
        recorder = nil
        state = .idle
    }

}
