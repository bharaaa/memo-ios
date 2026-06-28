//
//  SpeechService.swift
//  Memo
//
//  Wraps Apple's Speech and AVAudioSession for live transcription.
//

import Foundation
import Speech
import AVFoundation
import Observation

@MainActor
@Observable
final class SpeechService {
    
    // MARK: - State
    
    var isRecording = false
    var isAuthorized = false
    var transcript = ""
    var errorMessage: String? = nil
    
    // MARK: - Internal
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Auth
    
    func requestAuthorization() async {
        let authStatus = await SFSpeechRecognizer.hasAuthorizationToRecognize()
        self.isAuthorized = authStatus
        
        if authStatus {
            await AVAudioApplication.requestRecordPermission()
        }
    }
    
    // MARK: - Recording
    
    func startRecording() throws {
        // Reset state
        transcript = ""
        errorMessage = nil
        
        // Cancel previous task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Audio session config
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechServiceError.requestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Ensure on device if needed or let it use Apple servers
        if #available(iOS 13, *) {
            if speechRecognizer?.supportsOnDeviceRecognition == true {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                var isFinal = false
                
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
                
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.isRecording = false
                }
            }
        }
        
        // Configure audio engine
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
    }
    
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isRecording = false
        }
    }
}

enum SpeechServiceError: Error, LocalizedError {
    case requestFailed
    
    var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "Failed to start speech recognition request."
        }
    }
}

extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
