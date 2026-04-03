import SwiftUI

struct MainWindowWithStatusBar: View {
    @ObservedObject var coordinator: RecordingCoordinator
    let onStopRecording: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MainWindowView()
            BottomStatusBar(
                recordingManager: coordinator.recordingManager,
                appState: coordinator.appState,
                onStopRecording: onStopRecording
            )
        }
    }
}
