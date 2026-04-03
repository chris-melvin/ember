import AVKit
import SwiftUI

struct PlayerContainerView: View {
    let recording: Recording
    @EnvironmentObject var playbackState: PlaybackState

    var body: some View {
        VStack(spacing: 8) {
            if recording.isVideo, let player = playbackState.avPlayer {
                VideoPlayerRepresentable(player: player)
                    .frame(height: 200)
                    .cornerRadius(8)
            }

            // Transport controls
            HStack(spacing: 12) {
                Button {
                    playbackState.togglePlayPause()
                } label: {
                    Image(systemName: playbackState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

                // Seek bar
                SeekBar(
                    currentTime: $playbackState.currentTime,
                    duration: playbackState.duration,
                    onSeek: { time in
                        playbackState.seek(to: time)
                    }
                )

                // Time display
                Text("\(formatTime(playbackState.currentTime)) / \(formatTime(playbackState.duration))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 90, alignment: .trailing)
            }
        }
        .onAppear {
            playbackState.loadRecording(recording)
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        guard interval.isFinite && !interval.isNaN else { return "0:00" }
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SeekBar: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let progress = duration > 0 ? min(currentTime / duration, 1.0) : 0
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(.quaternary)
                    .frame(height: 4)

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(.primary.opacity(0.6))
                    .frame(width: geo.size.width * progress, height: 4)

                // Thumb
                Circle()
                    .fill(.primary)
                    .frame(width: 12, height: 12)
                    .offset(x: geo.size.width * progress - 6)
            }
            .frame(height: 12)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let fraction = max(0, min(value.location.x / geo.size.width, 1.0))
                        currentTime = fraction * duration
                    }
                    .onEnded { value in
                        isDragging = false
                        let fraction = max(0, min(value.location.x / geo.size.width, 1.0))
                        onSeek(fraction * duration)
                    }
            )
        }
        .frame(height: 12)
    }
}

struct VideoPlayerRepresentable: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.showsFullScreenToggleButton = false
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
