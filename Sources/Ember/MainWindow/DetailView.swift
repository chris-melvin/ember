import SwiftUI

struct DetailView: View {
    @Binding var recording: Recording
    @EnvironmentObject var store: RecordingStore
    @EnvironmentObject var playbackState: PlaybackState

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    HStack(spacing: 12) {
                        Text(Self.dateFormatter.string(from: recording.createdAt))
                        if recording.duration > 0 {
                            Text(formattedDuration)
                        }
                        Text(recording.isVideo ? "Video" : "Audio")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Player
                PlayerContainerView(recording: recording)
                    .environmentObject(playbackState)
                    .padding(.horizontal)

                Divider()

                // Transcript
                if recording.transcriptionStatus == .completed,
                   let text = recording.transcriptText, !text.isEmpty {
                    TranscriptView(
                        text: Binding(
                            get: { recording.transcriptText ?? "" },
                            set: { newText in
                                recording.transcriptText = newText
                                store.saveTranscript(newText, for: recording)
                            }
                        ),
                        playbackState: playbackState
                    )
                    .padding(.horizontal)
                } else if recording.transcriptionStatus == .pending {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Transcribing...")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    Text("No transcript available")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                Divider()

                // Tags
                TagEditorView(recording: $recording)
                    .environmentObject(store)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
        .frame(minWidth: 350)
    }

    private var formattedDuration: String {
        let total = Int(recording.duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
