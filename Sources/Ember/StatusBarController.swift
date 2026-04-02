import AppKit
import SwiftUI

enum AppState {
    case idle
    case recording
    case transcribing
}

class StatusBarController: ObservableObject {
    private let statusItem: NSStatusItem
    @Published var appState: AppState = .idle
    var onToggleRecording: (() -> Void)?
    var onOpenPreferences: (() -> Void)?
    var onOpenLibrary: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        setupMenu()
    }

    func updateState(_ state: AppState) {
        appState = state
        updateIcon()
        setupMenu()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbolName: String
        switch appState {
        case .idle:
            symbolName = "mic.circle"
        case .recording:
            symbolName = "record.circle.fill"
        case .transcribing:
            symbolName = "text.badge.checkmark"
        }
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Ember")
    }

    private func setupMenu() {
        let menu = NSMenu()

        let headerItem = NSMenuItem(title: "Ember", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        // Recording mode submenu
        let modeSubmenu = NSMenu()
        let videoItem = NSMenuItem(title: "Video + Audio", action: #selector(setVideoMode), keyEquivalent: "")
        videoItem.target = self
        let audioItem = NSMenuItem(title: "Audio Only", action: #selector(setAudioMode), keyEquivalent: "")
        audioItem.target = self

        let currentMode = RecordingMode(rawValue: UserDefaults.standard.string(forKey: "recordingMode") ?? "videoAndAudio") ?? .videoAndAudio
        videoItem.state = currentMode == .videoAndAudio ? .on : .off
        audioItem.state = currentMode == .audioOnly ? .on : .off

        modeSubmenu.addItem(videoItem)
        modeSubmenu.addItem(audioItem)

        let modeItem = NSMenuItem(title: "Recording Mode", action: nil, keyEquivalent: "")
        modeItem.submenu = modeSubmenu
        menu.addItem(modeItem)

        menu.addItem(NSMenuItem.separator())

        let recordTitle: String
        switch appState {
        case .idle:
            recordTitle = "Start Recording"
        case .recording:
            recordTitle = "Stop Recording"
        case .transcribing:
            recordTitle = "Transcribing..."
        }
        let recordItem = NSMenuItem(title: recordTitle, action: #selector(toggleRecording), keyEquivalent: "r")
        recordItem.keyEquivalentModifierMask = [.command, .shift]
        recordItem.target = self
        recordItem.isEnabled = appState != .transcribing
        menu.addItem(recordItem)

        menu.addItem(NSMenuItem.separator())

        let libraryItem = NSMenuItem(title: "Library", action: #selector(openLibrary), keyEquivalent: "l")
        libraryItem.keyEquivalentModifierMask = [.command]
        libraryItem.target = self
        menu.addItem(libraryItem)

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit Ember", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func toggleRecording() {
        onToggleRecording?()
    }

    @objc private func openPreferences() {
        onOpenPreferences?()
    }

    @objc private func openLibrary() {
        onOpenLibrary?()
    }

    @objc private func setVideoMode() {
        UserDefaults.standard.set(RecordingMode.videoAndAudio.rawValue, forKey: "recordingMode")
        setupMenu()
    }

    @objc private func setAudioMode() {
        UserDefaults.standard.set(RecordingMode.audioOnly.rawValue, forKey: "recordingMode")
        setupMenu()
    }
}
