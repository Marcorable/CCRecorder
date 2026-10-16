//
//  AudioPlayService.swift
//  Domain
//
//  Created by Yongwoo Marco on 2022/08/16.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common

import Combine
import AVFAudio

final class AudioPlayService: NSObject {
    
    let isPlayingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    let timeSubject: CurrentValueSubject<(current: TimeInterval, duration: TimeInterval), Never> = .init((.zero, .zero))
    var isPlaying: Bool { isPlayingSubject.value }
    var duration: TimeInterval { timeSubject.value.duration }
    
    private var progressTimer: AnyCancellable?
    private var audioPlayer: AVAudioPlayer?
	
    struct Dependency {
		let dataController: RecordRepository
	}
    private let dependency: Dependency
    private var cancellableSet: Set<AnyCancellable> = []
	
    init(dependency: Dependency) {
		self.dependency = dependency
		
		super.init()
		
        bind()
	}
	
}

extension AudioPlayService {
    
    private func bind() {
        NotificationCenter.default
            .publisher(for: AVAudioSession.routeChangeNotification)
            .compactMap(\.userInfo)
            .map({ $0[AVAudioSessionRouteChangeReasonKey] })
            .receive(on: DispatchQueue.main)
            .combineLatest(isPlayingSubject)
            .sink { [weak self] routeChangeReason, isPlaying in
                guard let routeChangeReasonDescription = routeChangeReason as? AVAudioSessionRouteDescription,
                      let resoneRawValue = routeChangeReason as? UInt,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: resoneRawValue),
                      let firstOutput = routeChangeReasonDescription.outputs.first else {
                    return
                }
                switch reason {
                    case .oldDeviceUnavailable:
                        if case .headphones =  firstOutput.portType {
                            if isPlaying {
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
            .combineLatest(isPlayingSubject)
            .sink { [weak self] userInfo, isPlaying in
                guard let interruptionTypeRawValue = [AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue),
                      let interruptionOptionRawValue = [AVAudioSessionInterruptionOptionKey] as? UInt
                else {
                    return
                }
                
                switch type {
                    case .began:
                        if isPlaying {
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
        
        isPlayingSubject
            .sink { [weak self] isPlaying in
                if isPlaying {
                    
                } else {
                    
                }
            }
            .store(in: &cancellableSet)
    }
    
}

extension AudioPlayService {
    
    private func makeAudioPlayer(by filePath: URL) -> AVAudioPlayer? {
        guard let data = dependency.dataController.read(of: filePath) else {
            CCError.log.append(.audioServiceFailed(reason: .fileURLPathInvalidated))
            return nil
        }
        do {
            return try AVAudioPlayer(data: data) // Test FileType 수정필요
        } catch {
            CCError.log.append(.audioServiceFailed(reason: .fileBindingFailure))
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
        let currentTime = audioPlayer?.currentTime ?? 0
        timeSubject.send((currentTime, duration))
    }
    
}

extension AudioPlayService: CCPlayer {
		
    func stopTrackingCurrentTime() {
		self.progressTimer?.cancel()
        self.progressTimer = nil
	}
	
    func setup(filePath: URL, completion: (CCError?) -> Void) {
		guard let audioPlayer = makeAudioPlayer(by: filePath) else {
			completion(.audioServiceFailed(reason: .fileBindingFailure))
			return
		}
		print(filePath)
		audioPlayer.enableRate = true
		audioPlayer.numberOfLoops = 0
		audioPlayer.volume = 1.0
		audioPlayer.delegate = self
        timeSubject.send((.zero, audioPlayer.duration))
		guard audioPlayer.prepareToPlay() else {
			completion(.audioServiceFailed(reason: .preparedFailure))
			return
		}
		self.audioPlayer = audioPlayer
		completion(nil)
	}
	
    func start() {
		audioPlayer?.play()
        isPlayingSubject.send(true)
		self.startTimer()
	}
	
    func pause() {
		self.audioPlayer?.pause()
        isPlayingSubject.send(false)
	}
	
    func finish() {
		if isPlaying {
			self.audioPlayer?.stop()
            isPlayingSubject.send(false)
		}
		self.audioPlayer = nil
        timeSubject.send((.zero, .zero))
	}
	
    func seek(to time: Double) {
		var seekPosition = time
		
		if seekPosition < 0 {
			seekPosition = 0
		} else if seekPosition > duration {
			seekPosition = duration
		}
		
		if isPlaying { self.audioPlayer?.stop() }
		self.audioPlayer?.currentTime = seekPosition
		if isPlaying {
			self.audioPlayer?.play()
			self.startTimer()
		}
	}
	
    func changePlayingRate(to value: Float) {
        self.audioPlayer?.rate = value
    }

    func removeRecordFile(from fileURL: URL, completion: (CCError?) -> Void) {
        try? dependency.dataController.delete(from: fileURL)
        completion(.audioServiceFailed(reason: .bindingFailure))
	}
	
}

extension AudioPlayService: AVAudioPlayerDelegate {
	
	public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		self.audioPlayer?.stop()
        timeSubject.send((.zero, duration))
        isPlayingSubject.send(false)
	}
	
}
