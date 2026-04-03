import SwiftUI

struct BottomStatusBar: View {
    @ObservedObject var recordingManager: RecordingManager
    let appState: AppState
    let onStopRecording: () -> Void

    var body: some View {
        HStack {
            switch appState {
            case .idle:
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Ready to record")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .recording:
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Recording \(RecordingManager.formattedTime(recordingManager.elapsedTime))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.red)

                Button {
                    onStopRecording()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)

            case .transcribing:
                ProgressView()
                    .scaleEffect(0.6)
                Text("Transcribing...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Mode: \(recordingManager.recordingMode == .audioOnly ? "Audio Only" : "Video + Audio")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Cmd+Shift+R")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary)
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
