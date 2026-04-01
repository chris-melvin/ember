import AppKit
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    var hotkeyManager: HotkeyManager!
    var recordingManager: RecordingManager!
    var transcriptionManager: TranscriptionManager!
    private var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        hotkeyManager = HotkeyManager()
        recordingManager = RecordingManager()
        transcriptionManager = TranscriptionManager()

        statusBarController.onToggleRecording = { [weak self] in
            self?.toggleRecording()
        }

        statusBarController.onOpenPreferences = { [weak self] in
            self?.showPreferences()
        }

        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.toggleRecording()
        }

        _ = HotkeyManager.checkAccessibilityPermission()
        hotkeyManager.start()
    }

    private func toggleRecording() {
        switch statusBarController.appState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .transcribing:
            break
        }
    }

    private func startRecording() {
        let vaultPath = UserDefaults.standard.string(forKey: "vaultPath")
        guard let vaultPath, !vaultPath.isEmpty else {
            showPreferences()
            return
        }

        let vaultURL = URL(fileURLWithPath: vaultPath)
        let recordingsDir = vaultURL.appendingPathComponent("ember/recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

        let transcriptionsDir = vaultURL.appendingPathComponent("ember/transcriptions", isDirectory: true)
        try? FileManager.default.createDirectory(at: transcriptionsDir, withIntermediateDirectories: true)

        let timestamp = Self.timestampFormatter.string(from: Date())
        let outputURL = recordingsDir.appendingPathComponent("\(timestamp).mp4")

        recordingManager.startRecording(outputURL: outputURL)
        statusBarController.updateState(.recording)
    }

    private func stopRecording() {
        recordingManager.stopRecording { [weak self] url in
            guard let self, let url else { return }
            self.statusBarController.updateState(.transcribing)
            self.transcribeRecording(at: url)
        }
    }

    private func transcribeRecording(at url: URL) {
        Task {
            do {
                try await transcriptionManager.transcribe(recordingURL: url)
                await MainActor.run {
                    statusBarController.updateState(.idle)
                    sendCompletionNotification(for: url)
                }
            } catch {
                await MainActor.run {
                    statusBarController.updateState(.idle)
                }
                print("Transcription error: \(error)")
            }
        }
    }

    private func sendCompletionNotification(for url: URL) {
        let content = UNMutableNotificationContent()
        content.title = "Transcription Complete"
        content.body = url.deletingPathExtension().lastPathComponent
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func showPreferences() {
        if let preferencesWindow, preferencesWindow.isVisible {
            preferencesWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let prefsView = PreferencesView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Ember Preferences"
        window.contentView = NSHostingView(rootView: prefsView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow = window
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f
    }()
}

import UserNotifications
