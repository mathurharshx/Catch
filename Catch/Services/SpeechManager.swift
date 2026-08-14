import SwiftUI
import Speech
import AVFoundation

/// Handles microphone recording and real-time speech-to-text transcription.
@MainActor
public final class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    public static let shared = SpeechManager()

    @Published public var isRecording: Bool = false
    @Published public var transcribedText: String = ""
    @Published public var audioLevel: Float = 0.0
    @Published public var isAvailable: Bool = false
    @Published public var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    override private init() {
        super.init()
        speechRecognizer?.delegate = self
        self.isAvailable = speechRecognizer?.isAvailable ?? false
        self.authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    /// Requests permission for both speech recognition and microphone
    public func requestAuthorization() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        self.authorizationStatus = speechStatus

        let micStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return speechStatus == .authorized && micStatus
    }

    /// Starts real-time audio capture and speech recognition
    public func startRecording() throws {
        // Stop any active task
        stopRecording()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "CatchSpeech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install audio tap for real-time transcription and audio level analysis
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, _) in
            self?.recognitionRequest?.append(buffer)

            // Calculate instantaneous audio level for waveform animation
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = UInt(buffer.frameLength)
            var sum: Float = 0.0
            for i in 0..<Int(frames) {
                sum += abs(channelData[i])
            }
            let avg = frames > 0 ? (sum / Float(frames)) : 0.0
            let normalized = min(max(avg * 5.0, 0.0), 1.0)

            Task { @MainActor in
                self?.audioLevel = normalized
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        transcribedText = ""

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
    }

    /// Stops the microphone and finishes the transcription task
    public func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
        audioLevel = 0.0

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            self.isAvailable = available
        }
    }
}
