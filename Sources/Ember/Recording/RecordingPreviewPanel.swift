import AppKit
import AVFoundation
import SwiftUI

class RecordingPreviewPanel {
    private var panel: NSPanel?
    private let captureSession: AVCaptureSession?
    private weak var recordingManager: RecordingManager?
    private let audioOnly: Bool
    private var titlePromptCompletion: ((String?) -> Void)?

    init(captureSession: AVCaptureSession?, recordingManager: RecordingManager, audioOnly: Bool = false) {
        self.captureSession = captureSession
        self.recordingManager = recordingManager
        self.audioOnly = audioOnly
    }

    func showPanel() {
        let panelWidth: CGFloat = 240
        let panelHeight: CGFloat = audioOnly ? 80 : 200

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
        panel.title = audioOnly ? "Recording Audio" : "Recording"
        panel.isMovableByWindowBackground = true

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        contentView.wantsLayer = true

        if !audioOnly, let session = captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = NSRect(x: 0, y: 44, width: panelWidth, height: panelHeight - 44)
            contentView.layer?.addSublayer(previewLayer)
        } else {
            // Audio-only: simple indicator
            let audioView = NSHostingView(rootView: AudioOnlyIndicator())
            audioView.frame = NSRect(x: 0, y: 44, width: panelWidth, height: panelHeight - 44)
            contentView.addSubview(audioView)
        }

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

    func showTitlePrompt(completion: @escaping (String?) -> Void) {
        guard let panel else {
            completion(nil)
            return
        }
        titlePromptCompletion = completion

        let panelWidth: CGFloat = 240
        let panelHeight: CGFloat = 120
        panel.setContentSize(NSSize(width: panelWidth, height: panelHeight))
        panel.title = "Name Recording"

        let titleView = NSHostingView(rootView: TitlePromptView(
            onSave: { [weak self] title in
                self?.titlePromptCompletion?(title)
                self?.titlePromptCompletion = nil
            },
            onSkip: { [weak self] in
                self?.titlePromptCompletion?(nil)
                self?.titlePromptCompletion = nil
            }
        ))
        titleView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        panel.contentView = titleView
    }

    func close() {
        panel?.close()
        panel = nil
    }
}

// MARK: - Subviews

struct AudioOnlyIndicator: View {
    @State private var pulse = false

    var body: some View {
        VStack {
            Image(systemName: "waveform")
                .font(.title)
                .foregroundStyle(.red)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.8))
        .onAppear { pulse = true }
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

struct TitlePromptView: View {
    let onSave: (String) -> Void
    let onSkip: () -> Void
    @State private var title: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("Name this recording")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("Title (optional)", text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    let trimmed = title.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty {
                        onSkip()
                    } else {
                        onSave(trimmed)
                    }
                }

            HStack {
                Button("Skip") { onSkip() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Save") {
                    let trimmed = title.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty {
                        onSkip()
                    } else {
                        onSave(trimmed)
                    }
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.black.opacity(0.9))
    }
}
