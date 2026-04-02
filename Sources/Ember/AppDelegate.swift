import AppKit
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    var hotkeyManager: HotkeyManager!
    var recordingManager: RecordingManager!
    var transcriptionManager: TranscriptionManager!
    private var preferencesWindow: NSWindow?

    private var libraryWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.migrateSettings()

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

        statusBarController.onOpenLibrary = { [weak self] in
            self?.showLibrary()
        }

        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.toggleRecording()
        }

        recordingManager.onStopRequested = { [weak self] in
            self?.stopRecording()
        }

        _ = HotkeyManager.checkAccessibilityPermission()
        hotkeyManager.start()

        // Download default whisper model on first launch if none available
        if !WhisperModelManager.shared.hasAnyModel() {
            Task {
                try? await WhisperModelManager.shared.ensureDefaultModel()
            }
        }
    }

    private static func migrateSettings() {
        let defaults = UserDefaults.standard
        if let oldPath = defaults.string(forKey: "vaultPath"), defaults.string(forKey: "outputFolderPath") == nil {
            defaults.set(oldPath, forKey: "outputFolderPath")
            defaults.removeObject(forKey: "vaultPath")
        }
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
        let outputPath = UserDefaults.standard.string(forKey: "outputFolderPath")
        guard let outputPath, !outputPath.isEmpty else {
            showPreferences()
            return
        }

        guard WhisperModelManager.shared.hasAnyModel() else {
            showAlert(title: "No Whisper Model", message: "A transcription model is required. Please download one in Preferences.")
            showPreferences()
            return
        }

        let outputURL = URL(fileURLWithPath: outputPath)
        let recordingsDir = outputURL.appendingPathComponent("ember/recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

        let transcriptionsDir = outputURL.appendingPathComponent("ember/transcriptions", isDirectory: true)
        try? FileManager.default.createDirectory(at: transcriptionsDir, withIntermediateDirectories: true)

        let timestamp = Self.timestampFormatter.string(from: Date())
        let isAudioOnly = recordingManager.recordingMode == .audioOnly
        let ext = isAudioOnly ? "m4a" : "mov"
        let tempURL = recordingsDir.appendingPathComponent("\(timestamp).\(ext)")

        recordingManager.startRecording(outputURL: tempURL)
        statusBarController.updateState(.recording)
    }

    private func stopRecording() {
        recordingManager.stopRecording { [weak self] url in
            guard let self, let url else { return }
            self.recordingManager.showTitlePrompt { [weak self] title in
                guard let self else { return }
                let finalURL = Self.renameWithTitle(url: url, title: title)
                self.statusBarController.updateState(.transcribing)
                self.transcribeRecording(at: finalURL, title: title)
            }
        }
    }

    private static func renameWithTitle(url: URL, title: String?) -> URL {
        guard let title, !title.trimmingCharacters(in: .whitespaces).isEmpty else { return url }
        let slug = Self.slugify(title)
        guard !slug.isEmpty else { return url }
        let dir = url.deletingLastPathComponent()
        let ext = url.pathExtension
        let baseName = url.deletingPathExtension().lastPathComponent
        let newName = "\(baseName)-\(slug).\(ext)"
        let newURL = dir.appendingPathComponent(newName)
        try? FileManager.default.moveItem(at: url, to: newURL)
        return newURL
    }

    private static func slugify(_ title: String) -> String {
        var slug = title.lowercased()
        slug = slug.replacingOccurrences(of: " ", with: "-")
        slug = slug.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        slug = slug.replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if slug.count > 60 {
            let truncated = slug.prefix(60)
            if let lastHyphen = truncated.lastIndex(of: "-") {
                slug = String(truncated[truncated.startIndex..<lastHyphen])
            } else {
                slug = String(truncated)
            }
        }
        return slug
    }

    private func showLibrary() {
        if let libraryWindow, libraryWindow.isVisible {
            libraryWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let libraryView = LibraryView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Ember Library"
        window.contentView = NSHostingView(rootView: libraryView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        libraryWindow = window
    }

    private func transcribeRecording(at url: URL, title: String? = nil) {
        Task {
            do {
                try await transcriptionManager.transcribe(recordingURL: url, title: title)
                await MainActor.run {
                    statusBarController.updateState(.idle)
                    sendCompletionNotification(for: url)
                }
            } catch {
                await MainActor.run {
                    statusBarController.updateState(.idle)
                    showTranscriptionError(error)
                }
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

    private func showTranscriptionError(_ error: Error) {
        let message: String
        if let whisperError = error as? WhisperError {
            switch whisperError {
            case .noModelAvailable:
                message = "No whisper model found. Please download one in Preferences."
            case .couldNotInitializeContext:
                message = "Failed to load the whisper model. Try downloading it again in Preferences."
            case .transcriptionFailed:
                message = "Transcription failed. The audio may be too short or corrupted."
            }
        } else {
            message = error.localizedDescription
        }
        showAlert(title: "Transcription Error", message: message)
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f
    }()
}

import UserNotifications
