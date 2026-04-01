import AVFoundation
import AppKit

class RecordingManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var previewPanel: RecordingPreviewPanel?
    private var completionHandler: ((URL?) -> Void)?
    private var recordingStartTime: Date?
    private var timer: Timer?

    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0

    var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    func startRecording(outputURL: URL) {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            print("Failed to set up video input")
            return
        }
        session.addInput(videoInput)

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

        captureSession = session
        movieOutput = output

        session.startRunning()
        output.startRecording(to: outputURL, recordingDelegate: self)

        recordingStartTime = Date()
        isRecording = true
        elapsedTime = 0

        DispatchQueue.main.async {
            self.showPreviewPanel()
            self.startTimer()
        }
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        completionHandler = completion
        movieOutput?.stopRecording()
        stopTimer()
    }

    private func showPreviewPanel() {
        guard let session = captureSession else { return }
        previewPanel = RecordingPreviewPanel(captureSession: session, recordingManager: self)
        previewPanel?.showPanel()
    }

    private func dismissPreviewPanel() {
        previewPanel?.close()
        previewPanel = nil
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

        DispatchQueue.main.async {
            self.dismissPreviewPanel()
        }

        if let error {
            print("Recording error: \(error)")
            completionHandler?(nil)
        } else {
            completionHandler?(outputFileURL)
        }
        completionHandler = nil
    }
}
