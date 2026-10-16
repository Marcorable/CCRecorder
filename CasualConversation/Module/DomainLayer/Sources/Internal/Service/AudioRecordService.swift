//
//  AudioRecordService.swift
//  Domain
//
//  Created by Yongwoo Marco on 2022/08/16.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common

import Combine
import AVFAudio

final class AudioRecordService: NSObject {
    
    let isRecordingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    let currentTimeSubject: CurrentValueSubject<TimeInterval, Never> = .init(.zero)
	
    private var isRecording: Bool { isRecordingSubject.value }
	
	private var audioRecorder: AVAudioRecorder?
    private var progressTimer: AnyCancellable?
    private var cancellableSet: Set<AnyCancellable> = []
    
    struct Dependency {
        let dataController: RecordRepository
    }
    private let dependency: Dependency
	
	public init(dependency: Dependency) {
		self.dependency = dependency
		
		super.init()
        
		bind()
	}
	
}

extension AudioRecordService: CCRecorder {
    
	public func setup(completion: (CCError?) -> Void) {
		guard let audioRecorder = makeAudioRecorder() else {
			completion(.audioServiceFailed(reason: .bindingFailure))
			return
		}
		audioRecorder.delegate = self
		guard audioRecorder.prepareToRecord() else {
			completion(.audioServiceFailed(reason: .preparedFailure))
			return
		}
		self.audioRecorder = audioRecorder
		completion(nil)
	}
	
	public func start() {
		while let recorder = self.audioRecorder {
			if recorder.record() {
                isRecordingSubject.send(true)
				self.stopTimer()
				break
			}
		}
	}
	
	public func pause() {
		self.audioRecorder?.pause()
        isRecordingSubject.send(false)
		self.stopTimer()
	}
	
	public func stop(completion: (Result<URL, CCError>) -> Void) {
		self.audioRecorder?.stop()
        isRecordingSubject.send(false)
		guard let savedFilePath = audioRecorder?.url else {
			completion(.failure(.audioServiceFailed(reason: .fileURLPathSavedFailure)))
			return
		}
		completion(.success(savedFilePath))
	}
	
	public func finish(isCancel: Bool) {
		if isRecording { self.audioRecorder?.stop() }
		if isCancel { self.audioRecorder?.deleteRecording() }
        self.audioRecorder = nil
        isRecordingSubject.send(false)
        currentTimeSubject.send(.zero)
	}
	
}

extension AudioRecordService {
    
    private func bind() {
        NotificationCenter.default
            .publisher(for: AVAudioSession.routeChangeNotification)
            .compactMap(\.userInfo)
            .map({ $0[AVAudioSessionRouteChangeReasonKey] })
            .receive(on: DispatchQueue.main)
            .combineLatest(isRecordingSubject)
            .sink { [weak self] routeChangeReason, isRecording in
                guard let routeChangeReasonDescription = routeChangeReason as? AVAudioSessionRouteDescription,
                      let resoneRawValue = routeChangeReason as? UInt,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: resoneRawValue),
                      let firstOutput = routeChangeReasonDescription.outputs.first else {
                    return
                }
                switch reason {
                    case .oldDeviceUnavailable:
                        if case .headphones =  firstOutput.portType {
                            if isRecording {
                                self?.pause()
                            }
                        }
                    default: break
                }
            }
            .store(in: &cancellableSet)
    
        NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .compactMap(\.userInfo)
            .receive(on: DispatchQueue.main)
            .combineLatest(isRecordingSubject)
            .sink { [weak self] userInfo, isRecording in
                guard let interruptionTypeRawValue = [AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue),
                      let interruptionOptionRawValue = [AVAudioSessionInterruptionOptionKey] as? UInt
                else {
                    return
                }
                
                switch type {
                    case .began:
                        if isRecording {
                            self?.pause()
                        }
                    case .ended:
                        if case .shouldResume = AVAudioSession.InterruptionOptions(rawValue: interruptionOptionRawValue) {
                            // restart audio or restart recording
                        }
                    @unknown default: fatalError("")
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func makeAudioRecorder() -> AVAudioRecorder? {
        let newRecordFileURL = dependency.dataController.newRecordFileURL
        let recordSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            print(newRecordFileURL)
            return try AVAudioRecorder(url: newRecordFileURL, settings: recordSettings)
        } catch {
            CCError.log.append(.catchError(error))
            return nil
        }
    }
    
    private func startTimer() {
        progressTimer = Timer
            .publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTime()
            }
    }
    
    private func stopTimer() {
        progressTimer?.cancel()
        progressTimer = nil
    }
    
    private func updateTime() {
        let currentTime = audioRecorder?.currentTime ?? 0
        currentTimeSubject.send(currentTime)
    }
    
}
 
extension AudioRecordService: AVAudioRecorderDelegate {
	
	public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecordingSubject.send(false) // TODO: 해당 상황 고민하기 (메모리 크기 등)
	}
	
}
