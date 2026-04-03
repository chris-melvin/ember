import AVFoundation
import Combine
import Foundation

class PlaybackState: ObservableObject {
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isPlaying = false

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var statusObservation: NSKeyValueObservation?
    private var positions: [String: TimeInterval] = [:]
    private var currentRecordingId: String?

    func loadRecording(_ recording: Recording) {
        guard let url = recording.recordingURL else { return }

        // Save current position before switching
        saveCurrentPosition()

        // Clean up previous player
        cleanup()

        currentRecordingId = recording.id
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        player = newPlayer

        // Observe player item status to get duration
        statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .readyToPlay else { return }
            DispatchQueue.main.async {
                self?.duration = CMTimeGetSeconds(item.duration)
            }
        }

        // Add periodic time observer (100ms)
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = CMTimeGetSeconds(time)

            // Detect playback end
            if let duration = self.player?.currentItem?.duration,
               CMTimeGetSeconds(time) >= CMTimeGetSeconds(duration) - 0.1 {
                self.isPlaying = false
            }
        }

        // Restore previous position if any
        if let savedPosition = positions[recording.id], savedPosition > 0 {
            newPlayer.seek(to: CMTime(seconds: savedPosition, preferredTimescale: 600))
            currentTime = savedPosition
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            // If at the end, restart
            if let duration = player.currentItem?.duration,
               currentTime >= CMTimeGetSeconds(duration) - 0.5 {
                player.seek(to: .zero)
            }
            player.play()
            isPlaying = true
        }
    }

    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
    }

    var avPlayer: AVPlayer? { player }

    private func saveCurrentPosition() {
        if let id = currentRecordingId {
            positions[id] = currentTime
        }
    }

    private func cleanup() {
        if let token = timeObserverToken, let player {
            player.removeTimeObserver(token)
        }
        timeObserverToken = nil
        statusObservation?.invalidate()
        statusObservation = nil
        player?.pause()
        player = nil
        isPlaying = false
    }

    deinit {
        cleanup()
    }
}
