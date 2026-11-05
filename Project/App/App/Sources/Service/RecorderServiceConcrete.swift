
import AVFAudio

import Domain

actor RecorderServiceConcrete {
    private var recorder: AVAudioRecorder?

    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    var currentTime: TimeInterval {
        recorder?.currentTime ?? .zero
    }

    init() {}
}

extension RecorderServiceConcrete: Service {

}

extension RecorderServiceConcrete: RecorderService {

    func prepare(with fileURL: URL) throws(DomainError.RecorderServiceFailure) {
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
                throw DomainError.RecorderServiceFailure.prepareFailed
            }

            self.recorder?.stop()
            self.recorder = recorder
        } catch let error as DomainError.RecorderServiceFailure {
            throw error
        } catch {
            throw DomainError.RecorderServiceFailure.prepareFailed
        }
    }

    func start() {
        guard
            let recorder,
            !recorder.isRecording,
            recorder.record()
        else {
            return
        }
    }

    func pause() {
        guard let recorder, recorder.isRecording else {
            return
        }
        recorder.pause()
    }

    func finish() throws(DomainError.RecorderServiceFailure) -> URL {
        guard let recorder else {
            throw DomainError.RecorderServiceFailure.notPrepared
        }

        let fileURL = recorder.url
        recorder.stop()
        self.recorder = nil

        return fileURL
    }

    func cancel() {
        recorder?.stop()
        recorder = nil
    }

}
