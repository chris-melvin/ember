import AppKit
import Carbon

class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    var onHotkeyPressed: (() -> Void)?

    // Default: Cmd+Shift+R
    var keyCode: UInt16 = UInt16(kVK_ANSI_R)
    var modifierFlags: NSEvent.ModifierFlags = [.command, .shift]

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let requiredFlags: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
        let eventFlags = event.modifierFlags.intersection(requiredFlags)
        let expectedFlags = modifierFlags.intersection(requiredFlags)

        if event.keyCode == keyCode && eventFlags == expectedFlags {
            onHotkeyPressed?()
        }
    }

    static func checkAccessibilityPermission(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    deinit {
        stop()
    }
}
