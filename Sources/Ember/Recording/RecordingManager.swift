import AVFoundation
import AppKit

enum RecordingMode: String {
    case videoAndAudio = "videoAndAudio"
    case audioOnly = "audioOnly"
}

class RecordingManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var previewPanel: RecordingPreviewPanel?
    private var completionHandler: ((URL?) -> Void)?
    private var recordingStartTime: Date?
    private var timer: Timer?

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

    private let sessionQueue = DispatchQueue(label: "com.ember.capture-session")

    func startRecording(outputURL: URL) {
        let session = AVCaptureSession()
        session.beginConfiguration()

        let isAudioOnly = recordingMode == .audioOnly

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

        let output = AVCaptureMovieFileOutput()
        output.maxRecordedDuration = .indefinite
        guard session.canAddOutput(output) else {
            print("Failed to add movie output")
            return
        }
        session.addOutput(output)

        session.commitConfiguration()

        captureSession = session
        movieOutput = output

        DispatchQueue.main.async {
            self.showPreviewPanel(audioOnly: isAudioOnly)
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            session.startRunning()
            Thread.sleep(forTimeInterval: 0.3)
            output.startRecording(to: outputURL, recordingDelegate: self)

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
            if let output = self.movieOutput, output.isRecording {
                output.stopRecording()
            }
            DispatchQueue.main.async {
                self.stopTimer()
            }
        }
    }

    func showTitlePrompt(on manager: RecordingManager, completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            self.previewPanel?.showTitlePrompt(completion: { title in
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
        captureSession = nil
        movieOutput = nil
        isRecording = false

        if let error {
            print("Recording error: \(error)")
            DispatchQueue.main.async {
                self.previewPanel?.close()
                self.previewPanel = nil
            }
            completionHandler?(nil)
        } else {
            completionHandler?(outputFileURL)
        }
        completionHandler = nil
    }
}
