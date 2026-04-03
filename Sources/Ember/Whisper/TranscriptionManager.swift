import AVFoundation
import Foundation

class TranscriptionManager: ObservableObject {
    @Published var isTranscribing = false
    @Published var progress: Double = 0

    func transcribe(recordingURL: URL, title: String? = nil, folderURL: URL) async throws {
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
        let wavURL = folderURL.appendingPathComponent("temp-audio.wav")
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

        // 5. Get segments and write transcript
        let segments = await whisperContext.getSegments()
        let duration = try await getRecordingDuration(url: recordingURL)
        try writeTranscript(to: folderURL, segments: segments)

        // 6. Update metadata with duration and transcription status
        updateMetadata(in: folderURL, title: title, duration: duration)

        // 7. Clean up temp WAV
        try? FileManager.default.removeItem(at: wavURL)

        await MainActor.run { progress = 1.0 }
    }

    // MARK: - Audio Extraction

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
        return Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
    }

    private func getRecordingDuration(url: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    // MARK: - Transcript Writing

    private func writeTranscript(to folderURL: URL, segments: [WhisperContext.Segment]) throws {
        let transcriptURL = folderURL.appendingPathComponent("transcript.md")
        var md = ""

        for segment in segments {
            let ts = formatTimestamp(ms: segment.startMs)
            md += "[\(ts)]\(segment.text)\n\n"
        }

        try md.write(to: transcriptURL, atomically: true, encoding: .utf8)
    }

    private func updateMetadata(in folderURL: URL, title: String?, duration: TimeInterval) {
        let metadataURL = folderURL.appendingPathComponent("metadata.json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? Data(contentsOf: metadataURL),
              var metadata = try? decoder.decode(RecordingMetadata.self, from: data) else { return }

        metadata.duration = duration
        metadata.transcriptionStatus = .completed
        if let title, !title.isEmpty {
            metadata.title = title
        }

        if let updatedData = try? encoder.encode(metadata) {
            try? updatedData.write(to: metadataURL, options: .atomic)
        }
    }

    private func formatTimestamp(ms: Int64) -> String {
        let totalSeconds = Int(ms / 1000)
        let hours = totalSeconds / 3600
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, (totalSeconds % 3600) / 60, totalSeconds % 60)
        }
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
