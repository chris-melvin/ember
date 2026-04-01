import AVFoundation
import Foundation

class TranscriptionManager: ObservableObject {
    @Published var isTranscribing = false
    @Published var progress: Double = 0

    func transcribe(recordingURL: URL) async throws {
        await MainActor.run {
            isTranscribing = true
            progress = 0
        }

        defer {
            Task { @MainActor in
                isTranscribing = false
                progress = 1.0
            }
        }

        // 1. Extract audio to WAV
        let wavURL = recordingURL.deletingPathExtension().appendingPathExtension("wav")
        try await extractAudio(from: recordingURL, to: wavURL)

        await MainActor.run { progress = 0.1 }

        // 2. Load audio samples
        let samples = try loadAudioSamples(from: wavURL)

        await MainActor.run { progress = 0.2 }

        // 3. Load whisper model
        guard let modelPath = WhisperModelManager.shared.activeModelPath() else {
            throw WhisperError.noModelAvailable
        }
        let whisperContext = try WhisperContext.createContext(path: modelPath.path)

        await MainActor.run { progress = 0.3 }

        // 4. Transcribe
        try await whisperContext.fullTranscribe(samples: samples)

        await MainActor.run { progress = 0.9 }

        // 5. Get segments and write markdown
        let segments = await whisperContext.getSegments()
        let duration = try await getRecordingDuration(url: recordingURL)
        try writeTranscriptMarkdown(for: recordingURL, segments: segments, duration: duration)

        // 6. Clean up temp WAV
        try? FileManager.default.removeItem(at: wavURL)

        await MainActor.run { progress = 1.0 }
    }

    private func extractAudio(from videoURL: URL, to outputURL: URL) async throws {
        let asset = AVAsset(url: videoURL)
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw WhisperError.transcriptionFailed
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]
        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(readerOutput)

        guard let outputFile = try? AVAudioFile(
            forWriting: outputURL,
            settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
            ],
            commonFormat: .pcmFormatInt16,
            interleaved: false
        ) else {
            throw WhisperError.transcriptionFailed
        }

        reader.startReading()

        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)

            if let dataPointer, length > 0 {
                let data = Data(bytes: dataPointer, count: length)
                let format = outputFile.processingFormat
                let frameCount = UInt32(length) / UInt32(format.streamDescription.pointee.mBytesPerFrame)
                if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
                    buffer.frameLength = frameCount
                    let audioData = buffer.int16ChannelData![0]
                    data.withUnsafeBytes { rawPtr in
                        let src = rawPtr.bindMemory(to: Int16.self)
                        audioData.update(from: src.baseAddress!, count: Int(frameCount))
                    }
                    try outputFile.write(from: buffer)
                }
            }
        }
    }

    private func loadAudioSamples(from wavURL: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: wavURL)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
        let frameCount = UInt32(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw WhisperError.transcriptionFailed
        }
        try file.read(into: buffer)
        let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
        return floatArray
    }

    private func getRecordingDuration(url: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    private func writeTranscriptMarkdown(for recordingURL: URL, segments: [WhisperContext.Segment], duration: TimeInterval) throws {
        let filename = recordingURL.deletingPathExtension().lastPathComponent
        let recordingsDir = recordingURL.deletingLastPathComponent()
        let vaultEmberDir = recordingsDir.deletingLastPathComponent()
        let transcriptionsDir = vaultEmberDir.appendingPathComponent("transcriptions", isDirectory: true)
        try FileManager.default.createDirectory(at: transcriptionsDir, withIntermediateDirectories: true)

        let transcriptURL = transcriptionsDir.appendingPathComponent("\(filename).md")

        let durationMinutes = Int(duration) / 60
        let durationSeconds = Int(duration) % 60
        let durationStr = String(format: "%d:%02d", durationMinutes, durationSeconds)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateStr = dateFormatter.string(from: Date())

        let titleFromFilename = filename
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "  ", with: " ")

        var md = """
        ---
        title: "\(titleFromFilename)"
        date: \(dateStr)
        duration: "\(durationStr)"
        recording: "[[ember/recordings/\(filename).mp4]]"
        tags: [ember/transcript]
        ---

        """

        for segment in segments {
            let startTimestamp = formatTimestamp(ms: segment.startMs)
            md += "\n[\(startTimestamp)]\(segment.text)\n"
        }

        try md.write(to: transcriptURL, atomically: true, encoding: .utf8)
    }

    private func formatTimestamp(ms: Int64) -> String {
        let totalSeconds = Int(ms / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
