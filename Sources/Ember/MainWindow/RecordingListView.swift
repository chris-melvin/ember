import SwiftUI

struct RecordingListView: View {
    let recordings: [Recording]
    @Binding var selectedRecording: Recording?
    @Binding var showDeleteConfirmation: Bool

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        List(recordings, selection: $selectedRecording) { recording in
            RecordingRowView(recording: recording)
                .tag(recording)
                .contextMenu {
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([recording.folderURL])
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        selectedRecording = recording
                        showDeleteConfirmation = true
                    }
                }
        }
        .listStyle(.inset)
        .frame(minWidth: 250)
        .overlay {
            if recordings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No recordings")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct RecordingRowView: View {
    let recording: Recording

    var body: some View {
        HStack {
            Image(systemName: recording.isVideo ? "video.fill" : "mic.fill")
                .foregroundStyle(recording.isVideo ? .blue : .orange)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(recording.title)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(RecordingListView.dateFormatter.string(from: recording.createdAt))
                    if recording.duration > 0 {
                        Text(formattedDuration)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if recording.transcriptionStatus == .completed {
                Text("Transcribed")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 2)
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
