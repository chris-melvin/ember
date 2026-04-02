import AVFoundation
import AppKit

enum RecordingMode: String {
    case videoAndAudio = "videoAndAudio"
    case audioOnly = "audioOnly"
}

class RecordingManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var audioFileOutput: AVCaptureAudioFileOutput?
    private var previewPanel: RecordingPreviewPanel?
    private var completionHandler: ((URL?) -> Void)?
    private var recordingStartTime: Date?
    private var timer: Timer?
    private var currentOutputURL: URL?
    private var isAudioOnlyRecording = false

    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0

    var recordingMode: RecordingMode {
        get {
            RecordingMode(rawValue: UserDefaults.standard.string(forKey: "recordingMode") ?? "videoAndAudio") ?? .videoAndAudio
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "recordingMode")
            objectWillChange.send()
        }
    }

    // External stop handler — set by AppDelegate so the panel stop button
    // goes through the same flow as hotkey/menu stop.
    var onStopRequested: (() -> Void)?

    private let sessionQueue = DispatchQueue(label: "com.ember.capture-session")

    func startRecording(outputURL: URL) {
        let session = AVCaptureSession()
        session.beginConfiguration()

        let isAudioOnly = recordingMode == .audioOnly
        isAudioOnlyRecording = isAudioOnly
        currentOutputURL = outputURL

        if !isAudioOnly {
            session.sessionPreset = .high
            guard let videoDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  session.canAddInput(videoInput) else {
                print("Failed to set up video input")
                return
            }
            session.addInput(videoInput)
        }

        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              session.canAddInput(audioInput) else {
            print("Failed to set up audio input")
            return
        }
        session.addInput(audioInput)

        if isAudioOnly {
            let audioOutput = AVCaptureAudioFileOutput()
            guard session.canAddOutput(audioOutput) else {
                print("Failed to add audio output")
                return
            }
            session.addOutput(audioOutput)
            audioFileOutput = audioOutput
            movieOutput = nil
        } else {
            let output = AVCaptureMovieFileOutput()
            output.maxRecordedDuration = .indefinite
            guard session.canAddOutput(output) else {
                print("Failed to add movie output")
                return
            }
            session.addOutput(output)
            movieOutput = output
            audioFileOutput = nil
        }

        session.commitConfiguration()
        captureSession = session

        DispatchQueue.main.async {
            self.showPreviewPanel(audioOnly: isAudioOnly)
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            session.startRunning()

            // Wait for session to be running before starting file output
            var attempts = 0
            while !session.isRunning && attempts < 10 {
                Thread.sleep(forTimeInterval: 0.05)
                attempts += 1
            }

            if isAudioOnly, let audioOutput = self.audioFileOutput {
                audioOutput.startRecording(to: outputURL, outputFileType: .m4a, recordingDelegate: self)
            } else if let movieOutput = self.movieOutput {
                movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            }

            DispatchQueue.main.async {
                self.recordingStartTime = Date()
                self.isRecording = true
                self.elapsedTime = 0
                self.startTimer()
            }
        }
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        completionHandler = completion
        sessionQueue.async { [weak self] in
            guard let self else { return }

            var didStop = false
            if let output = self.movieOutput, output.isRecording {
                output.stopRecording()
                didStop = true
            } else if let output = self.audioFileOutput, output.isRecording {
                output.stopRecording()
                didStop = true
            }

            if !didStop {
                // Recording hasn't started yet or already stopped — call completion immediately
                DispatchQueue.main.async {
                    self.cleanup()
                    self.completionHandler?(nil)
                    self.completionHandler = nil
                }
            }

            DispatchQueue.main.async {
                self.stopTimer()
            }
        }
    }

    func showTitlePrompt(completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            guard let panel = self.previewPanel else {
                completion(nil)
                return
            }
            panel.showTitlePrompt(completion: { title in
                self.previewPanel?.close()
                self.previewPanel = nil
                completion(title)
            })
        }
    }

    private func showPreviewPanel(audioOnly: Bool = false) {
        previewPanel = RecordingPreviewPanel(
            captureSession: audioOnly ? nil : captureSession,
            recordingManager: self,
            audioOnly: audioOnly
        )
        previewPanel?.showPanel()
    }

    private func cleanup() {
        stopTimer()
        isRecording = false
        elapsedTime = 0
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let start = self.recordingStartTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    static func formattedTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension RecordingManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        captureSession?.stopRunning()

        DispatchQueue.main.async {
            self.captureSession = nil
            self.movieOutput = nil
            self.audioFileOutput = nil
            self.isRecording = false
            self.stopTimer()

            if let error {
                print("Recording error: \(error)")
                self.previewPanel?.close()
                self.previewPanel = nil
                self.completionHandler?(nil)
            } else {
                self.completionHandler?(outputFileURL)
            }
            self.completionHandler = nil
        }
    }
}
