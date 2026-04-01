import AppKit
import AVFoundation
import SwiftUI

class RecordingPreviewPanel {
    private var panel: NSPanel?
    private let captureSession: AVCaptureSession
    private weak var recordingManager: RecordingManager?

    init(captureSession: AVCaptureSession, recordingManager: RecordingManager) {
        self.captureSession = captureSession
        self.recordingManager = recordingManager
    }

    func showPanel() {
        let panelWidth: CGFloat = 240
        let panelHeight: CGFloat = 200

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let origin = NSPoint(
            x: screenFrame.maxX - panelWidth - 16,
            y: screenFrame.maxY - panelHeight - 16
        )

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: panelWidth, height: panelHeight)),
            styleMask: [.titled, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.title = "Recording"
        panel.isMovableByWindowBackground = true

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))

        // Camera preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = NSRect(x: 0, y: 44, width: panelWidth, height: panelHeight - 44)
        contentView.wantsLayer = true
        contentView.layer?.addSublayer(previewLayer)

        // Bottom bar with timer and stop button
        let controls = RecordingControls(
            onStop: { [weak self] in
                self?.recordingManager?.stopRecording { _ in }
            },
            recordingManager: recordingManager!
        )
        let bottomBar = NSHostingView(rootView: controls)
        bottomBar.frame = NSRect(x: 0, y: 0, width: panelWidth, height: 44)
        contentView.addSubview(bottomBar)

        panel.contentView = contentView
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func close() {
        panel?.close()
        panel = nil
    }
}

struct RecordingControls: View {
    let onStop: () -> Void
    @ObservedObject var recordingManager: RecordingManager

    var body: some View {
        HStack {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)

            Text(RecordingManager.formattedTime(recordingManager.elapsedTime))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)

            Spacer()

            Button(action: onStop) {
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(.black.opacity(0.8))
    }
}
