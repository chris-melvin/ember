import Foundation
import Combine

class RecordingCoordinator: ObservableObject {
    static let shared = RecordingCoordinator()

    @Published var appState: AppState = .idle
    let recordingManager = RecordingManager()
    let transcriptionManager = TranscriptionManager()
}
