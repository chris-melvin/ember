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
}
