import Foundation

struct RecordingMetadata: Codable {
    var title: String
    var createdAt: Date
    var duration: TimeInterval
    var type: RecordingType
    var tags: [String]
    var transcriptionStatus: TranscriptionStatus
    var editedAt: Date?

    enum RecordingType: String, Codable {
        case video
        case audio
    }

    enum TranscriptionStatus: String, Codable {
        case completed
        case pending
        case none
    }
}

struct Recording: Identifiable {
    let id: String
    var title: String
    var createdAt: Date
    var duration: TimeInterval
    var type: RecordingMetadata.RecordingType
    var tags: [String]
    var transcriptionStatus: RecordingMetadata.TranscriptionStatus
    var editedAt: Date?
    var folderURL: URL
    var transcriptText: String?

    var recordingURL: URL? {
        let fm = FileManager.default
        for ext in ["mov", "mp4", "m4a"] {
            let url = folderURL.appendingPathComponent("recording.\(ext)")
            if fm.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    var transcriptURL: URL {
        folderURL.appendingPathComponent("transcript.md")
    }

    var metadataURL: URL {
        folderURL.appendingPathComponent("metadata.json")
    }

    var metadata: RecordingMetadata {
        RecordingMetadata(
            title: title,
            createdAt: createdAt,
            duration: duration,
            type: type,
            tags: tags,
            transcriptionStatus: transcriptionStatus,
            editedAt: editedAt
        )
    }

    var isVideo: Bool { type == .video }
}

extension Recording: Hashable {
    static func == (lhs: Recording, rhs: Recording) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
