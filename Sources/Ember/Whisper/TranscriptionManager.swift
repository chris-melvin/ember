import AVFoundation
import Foundation

class TranscriptionManager: ObservableObject {
    @Published var isTranscribing = false
    @Published var progress: Double = 0

    func transcribe(recordingURL: URL, title: String? = nil) async throws {
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

        // 5. Get segments and write transcript
        let segments = await whisperContext.getSegments()
        let duration = try await getRecordingDuration(url: recordingURL)
        let format = TranscriptFormat(rawValue: UserDefaults.standard.string(forKey: "transcriptFormat") ?? "markdown") ?? .markdown
        try writeTranscript(for: recordingURL, segments: segments, duration: duration, title: title, format: format)

        // 6. Clean up temp WAV
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

    private func writeTranscript(for recordingURL: URL, segments: [WhisperContext.Segment], duration: TimeInterval, title: String?, format: TranscriptFormat) throws {
        let filename = recordingURL.deletingPathExtension().lastPathComponent
        let recordingsDir = recordingURL.deletingLastPathComponent()
        let emberDir = recordingsDir.deletingLastPathComponent()
        let transcriptionsDir = emberDir.appendingPathComponent("transcriptions", isDirectory: true)
        try FileManager.default.createDirectory(at: transcriptionsDir, withIntermediateDirectories: true)

        switch format {
        case .markdown:
            try writeMarkdown(to: transcriptionsDir, filename: filename, recordingURL: recordingURL, segments: segments, duration: duration, title: title)
        case .plainText:
            try writePlainText(to: transcriptionsDir, filename: filename, segments: segments)
        case .srt:
            try writeSRT(to: transcriptionsDir, filename: filename, segments: segments)
        }
    }

    private func writeMarkdown(to dir: URL, filename: String, recordingURL: URL, segments: [WhisperContext.Segment], duration: TimeInterval, title: String?) throws {
        let transcriptURL = dir.appendingPathComponent("\(filename).md")
        let durationStr = String(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60)
        let dateStr = ISO8601DateFormatter().string(from: Date())
        let displayTitle = title ?? filename.replacingOccurrences(of: "-", with: " ")
        let recordingFilename = recordingURL.lastPathComponent
        let obsidianEnabled = UserDefaults.standard.object(forKey: "obsidianCompatibility") == nil ? true : UserDefaults.standard.bool(forKey: "obsidianCompatibility")
        let recordingRef: String
        if obsidianEnabled {
            recordingRef = "\"[[ember/recordings/\(recordingFilename)]]\""
        } else {
            recordingRef = "../recordings/\(recordingFilename)"
        }

        var md = """
        ---
        title: "\(displayTitle)"
        date: \(dateStr)
        duration: "\(durationStr)"
        recording: \(recordingRef)
        tags: [ember/transcript]
        ---

        """

        for segment in segments {
            let ts = formatTimestamp(ms: segment.startMs)
            md += "\n[\(ts)]\(segment.text)\n"
        }

        try md.write(to: transcriptURL, atomically: true, encoding: .utf8)
    }

    private func writePlainText(to dir: URL, filename: String, segments: [WhisperContext.Segment]) throws {
        let url = dir.appendingPathComponent("\(filename).txt")
        let text = segments.map { $0.text.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func writeSRT(to dir: URL, filename: String, segments: [WhisperContext.Segment]) throws {
        let url = dir.appendingPathComponent("\(filename).srt")
        var srt = ""
        for (i, segment) in segments.enumerated() {
            let startTime = srtTimestamp(ms: segment.startMs)
            let endTime = srtTimestamp(ms: segment.endMs)
            srt += "\(i + 1)\n"
            srt += "\(startTime) --> \(endTime)\n"
            srt += "\(segment.text.trimmingCharacters(in: .whitespaces))\n\n"
        }
        try srt.write(to: url, atomically: true, encoding: .utf8)
    }

    private func formatTimestamp(ms: Int64) -> String {
        let totalSeconds = Int(ms / 1000)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private func srtTimestamp(ms: Int64) -> String {
        let totalMs = Int(ms)
        let hours = totalMs / 3_600_000
        let minutes = (totalMs % 3_600_000) / 60_000
        let seconds = (totalMs % 60_000) / 1_000
        let millis = totalMs % 1_000
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, millis)
    }
}
