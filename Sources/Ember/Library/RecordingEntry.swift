import Foundation

struct RecordingEntry: Identifiable {
    let id: String
    let title: String
    let date: Date?
    let duration: String
    let type: RecordingType
    let transcriptionStatus: TranscriptionStatus
    let recordingURL: URL
    let transcriptURL: URL?

    enum RecordingType: String {
        case video = "Video"
        case audio = "Audio"
    }

    enum TranscriptionStatus: String {
        case transcribed = "Transcribed"
        case none = "None"
    }
}
