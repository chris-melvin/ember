import AppKit
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    var hotkeyManager: HotkeyManager!
    private let coordinator = RecordingCoordinator.shared
    private var recordingManager: RecordingManager { coordinator.recordingManager }
    private var transcriptionManager: TranscriptionManager { coordinator.transcriptionManager }
    private var preferencesWindow: NSWindow?

    private var libraryWindow: NSWindow?
    private var currentRecordingFolder: URL?
    private var currentRecordingTimestamp: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.migrateSettings()

        statusBarController = StatusBarController()
        hotkeyManager = HotkeyManager()

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

        // Only prompt for accessibility on first launch; check silently after
        let hasPrompted = UserDefaults.standard.bool(forKey: "hasPromptedAccessibility")
        if !hasPrompted {
            _ = HotkeyManager.checkAccessibilityPermission(prompt: true)
            UserDefaults.standard.set(true, forKey: "hasPromptedAccessibility")
        }
        hotkeyManager.start()

        // Download default whisper model on first launch if none available
        if !WhisperModelManager.shared.hasAnyModel() {
            Task {
                try? await WhisperModelManager.shared.ensureDefaultModel()
            }
        }

        // Migrate old storage format if needed
        let migrator = StorageMigrator()
        if migrator.needsMigration() {
            migrator.showMigrationDialogAndMigrate()
        }

        // Initial scan for library
        RecordingStore.shared.scan()
    }

    private static func migrateSettings() {
        let defaults = UserDefaults.standard
        if let oldPath = defaults.string(forKey: "vaultPath"), defaults.string(forKey: "outputFolderPath") == nil {
            defaults.set(oldPath, forKey: "outputFolderPath")
            defaults.removeObject(forKey: "vaultPath")
        }
    }

    private func toggleRecording() {
        switch coordinator.appState {
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

        let timestamp = Self.timestampFormatter.string(from: Date())
        let isAudioOnly = recordingManager.recordingMode == .audioOnly
        let ext = isAudioOnly ? "m4a" : "mov"

        // Create co-located folder for this recording
        guard let folderURL = RecordingStore.shared.createRecordingFolder(timestamp: timestamp, slug: nil) else {
            showAlert(title: "Error", message: "Could not create recording folder.")
            return
        }

        currentRecordingFolder = folderURL
        currentRecordingTimestamp = timestamp
        let recordingURL = folderURL.appendingPathComponent("recording.\(ext)")

        recordingManager.startRecording(outputURL: recordingURL)
        updateAppState(.recording)
    }

    private func stopRecording() {
        recordingManager.stopRecording { [weak self] url in
            guard let self, let url else { return }
            self.recordingManager.showTitlePrompt { [weak self] title in
                guard let self else { return }
                let folderURL = self.renameRecordingFolder(title: title)
                let isAudioOnly = self.recordingManager.recordingMode == .audioOnly
                let type: RecordingMetadata.RecordingType = isAudioOnly ? .audio : .video

                // Write initial metadata
                RecordingStore.shared.writeInitialMetadata(to: folderURL, title: title, type: type)

                // Find the recording file in the (possibly renamed) folder
                let ext = isAudioOnly ? "m4a" : "mov"
                let recordingURL = folderURL.appendingPathComponent("recording.\(ext)")

                self.updateAppState(.transcribing)
                self.transcribeRecording(at: recordingURL, title: title, folderURL: folderURL)
                self.currentRecordingFolder = nil
                self.currentRecordingTimestamp = nil
            }
        }
    }

    private func renameRecordingFolder(title: String?) -> URL {
        guard let folderURL = currentRecordingFolder,
              let timestamp = currentRecordingTimestamp,
              let title, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return currentRecordingFolder ?? URL(fileURLWithPath: "/")
        }
        let slug = Self.slugify(title)
        guard !slug.isEmpty else { return folderURL }
        let parentDir = folderURL.deletingLastPathComponent()
        let newFolderURL = parentDir.appendingPathComponent("\(timestamp)-\(slug)", isDirectory: true)
        if !FileManager.default.fileExists(atPath: newFolderURL.path) {
            try? FileManager.default.moveItem(at: folderURL, to: newFolderURL)
            return newFolderURL
        }
        return folderURL
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

        let mainView = MainWindowWithStatusBar(
            coordinator: coordinator,
            onStopRecording: { [weak self] in
                self?.stopRecording()
            }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Ember"
        window.minSize = NSSize(width: 800, height: 500)
        window.contentView = NSHostingView(rootView: mainView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        libraryWindow = window
    }

    private func transcribeRecording(at url: URL, title: String? = nil, folderURL: URL) {
        Task {
            do {
                try await transcriptionManager.transcribe(recordingURL: url, title: title, folderURL: folderURL)
                await MainActor.run {
                    updateAppState(.idle)
                    sendCompletionNotification(for: url)
                    RecordingStore.shared.scan()
                }
            } catch {
                await MainActor.run {
                    updateAppState(.idle)
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

    private func updateAppState(_ state: AppState) {
        coordinator.appState = state
        statusBarController.updateState(state)
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f
    }()
}

import UserNotifications
