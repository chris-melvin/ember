import AppKit
import Foundation

class StorageMigrator {
    private let fm = FileManager.default

    private var emberDir: URL? {
        guard let path = UserDefaults.standard.string(forKey: "outputFolderPath"), !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("ember", isDirectory: true)
    }

    // MARK: - Detection

    func needsMigration() -> Bool {
        guard let emberDir else { return false }
        let recordingsDir = emberDir.appendingPathComponent("recordings", isDirectory: true)

        guard let files = try? fm.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: nil) else {
            return false
        }

        let mediaExtensions: Set<String> = ["mov", "mp4", "m4a"]
        return files.contains { mediaExtensions.contains($0.pathExtension.lowercased()) }
    }

    // MARK: - Migration

    struct MigrationResult {
        var migrated: Int = 0
        var failed: [(filename: String, error: String)] = []
    }

    func migrate() -> MigrationResult {
        guard let emberDir else { return MigrationResult() }
        let recordingsDir = emberDir.appendingPathComponent("recordings", isDirectory: true)
        let transcriptionsDir = emberDir.appendingPathComponent("transcriptions", isDirectory: true)

        guard let recordingFiles = try? fm.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: [.creationDateKey]) else {
            return MigrationResult()
        }

        let mediaExtensions: Set<String> = ["mov", "mp4", "m4a"]
        var result = MigrationResult()

        for fileURL in recordingFiles {
            let ext = fileURL.pathExtension.lowercased()
            guard mediaExtensions.contains(ext) else { continue }

            let baseName = fileURL.deletingPathExtension().lastPathComponent

            do {
                // Create co-located folder
                let folderURL = emberDir.appendingPathComponent(baseName, isDirectory: true)
                try fm.createDirectory(at: folderURL, withIntermediateDirectories: true)

                // Move recording file
                let destRecording = folderURL.appendingPathComponent("recording.\(ext)")
                try fm.moveItem(at: fileURL, to: destRecording)

                // Find and migrate transcript
                let transcriptExtensions = ["md", "txt", "srt"]
                var transcriptFound = false
                var parsedTitle: String?
                var parsedDate: Date?
                var parsedDuration: String?

                for tExt in transcriptExtensions {
                    let transcriptURL = transcriptionsDir.appendingPathComponent("\(baseName).\(tExt)")
                    if fm.fileExists(atPath: transcriptURL.path) {
                        let content = try String(contentsOf: transcriptURL, encoding: .utf8)

                        if tExt == "md" {
                            let (frontmatter, body) = parseFrontmatter(content)
                            parsedTitle = frontmatter["title"]
                            parsedDuration = frontmatter["duration"]
                            if let dateStr = frontmatter["date"] {
                                parsedDate = ISO8601DateFormatter().date(from: dateStr)
                            }
                            // Write clean transcript (stripped of frontmatter)
                            let destTranscript = folderURL.appendingPathComponent("transcript.md")
                            try body.write(to: destTranscript, atomically: true, encoding: .utf8)
                        } else {
                            // For txt/srt, just copy as transcript.md
                            let destTranscript = folderURL.appendingPathComponent("transcript.md")
                            try content.write(to: destTranscript, atomically: true, encoding: .utf8)
                        }

                        try fm.removeItem(at: transcriptURL)
                        transcriptFound = true
                        break
                    }
                }

                // Generate metadata.json
                let fileDate = parsedDate ?? (try? fm.attributesOfItem(atPath: destRecording.path)[.creationDate] as? Date) ?? Date()
                let durationSeconds = parseDuration(parsedDuration)
                let type: RecordingMetadata.RecordingType = ext == "m4a" ? .audio : .video
                let displayTitle = parsedTitle ?? baseName.replacingOccurrences(of: "-", with: " ")

                let metadata = RecordingMetadata(
                    title: displayTitle,
                    createdAt: fileDate,
                    duration: durationSeconds,
                    type: type,
                    tags: [],
                    transcriptionStatus: transcriptFound ? .completed : .none,
                    editedAt: nil
                )

                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(metadata)
                try data.write(to: folderURL.appendingPathComponent("metadata.json"), options: .atomic)

                result.migrated += 1
            } catch {
                result.failed.append((filename: fileURL.lastPathComponent, error: error.localizedDescription))
            }
        }

        // Clean up empty old directories
        cleanupIfEmpty(recordingsDir)
        cleanupIfEmpty(transcriptionsDir)

        return result
    }

    // MARK: - Show Migration Dialog

    func showMigrationDialogAndMigrate() {
        let alert = NSAlert()
        alert.messageText = "Reorganize Recordings"
        alert.informativeText = "Ember needs to reorganize your recordings into a new folder structure. Each recording will be placed in its own folder. This is a one-time operation."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Proceed")
        alert.addButton(withTitle: "Later")

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let result = migrate()

        let summary = NSAlert()
        if result.failed.isEmpty {
            summary.messageText = "Migration Complete"
            summary.informativeText = "\(result.migrated) recording\(result.migrated == 1 ? "" : "s") reorganized successfully."
            summary.alertStyle = .informational
        } else {
            summary.messageText = "Migration Completed with Issues"
            let failedNames = result.failed.map { $0.filename }.joined(separator: ", ")
            summary.informativeText = "\(result.migrated) recording\(result.migrated == 1 ? "" : "s") migrated. \(result.failed.count) failed: \(failedNames)"
            summary.alertStyle = .warning
        }
        summary.addButton(withTitle: "OK")
        summary.runModal()
    }

    // MARK: - Helpers

    private func parseFrontmatter(_ content: String) -> (fields: [String: String], body: String) {
        var fields: [String: String] = [:]
        let lines = content.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return (fields, content)
        }

        var bodyStartIndex = 1
        for (i, line) in lines.dropFirst().enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "---" {
                bodyStartIndex = i + 2 // +1 for dropFirst, +1 for the --- line
                break
            }
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                var value = parts[1].trimmingCharacters(in: .whitespaces)
                value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                fields[key] = value
            }
        }

        let body = lines.dropFirst(bodyStartIndex).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (fields, body)
    }

    private func parseDuration(_ str: String?) -> TimeInterval {
        guard let str else { return 0 }
        let parts = str.split(separator: ":").compactMap { Int($0) }
        if parts.count == 2 {
            return TimeInterval(parts[0] * 60 + parts[1])
        } else if parts.count == 3 {
            return TimeInterval(parts[0] * 3600 + parts[1] * 60 + parts[2])
        }
        return 0
    }

    private func cleanupIfEmpty(_ dirURL: URL) {
        guard let contents = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil),
              contents.isEmpty else { return }
        try? fm.removeItem(at: dirURL)
    }
}
