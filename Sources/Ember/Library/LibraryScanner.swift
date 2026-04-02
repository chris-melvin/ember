import Foundation

class LibraryScanner: ObservableObject {
    @Published var entries: [RecordingEntry] = []

    func scan() {
        guard let outputPath = UserDefaults.standard.string(forKey: "outputFolderPath"), !outputPath.isEmpty else {
            entries = []
            return
        }

        let outputURL = URL(fileURLWithPath: outputPath)
        let recordingsDir = outputURL.appendingPathComponent("ember/recordings", isDirectory: true)
        let transcriptionsDir = outputURL.appendingPathComponent("ember/transcriptions", isDirectory: true)

        let fm = FileManager.default
        guard let recordingFiles = try? fm.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: [.creationDateKey]) else {
            entries = []
            return
        }

        let mediaExtensions: Set<String> = ["mov", "mp4", "m4a"]
        var results: [RecordingEntry] = []

        for fileURL in recordingFiles {
            let ext = fileURL.pathExtension.lowercased()
            guard mediaExtensions.contains(ext) else { continue }

            let baseName = fileURL.deletingPathExtension().lastPathComponent
            let type: RecordingEntry.RecordingType = ext == "m4a" ? .audio : .video

            // Look for matching transcript
            let transcriptExtensions = ["md", "txt", "srt"]
            var transcriptURL: URL?
            for tExt in transcriptExtensions {
                let candidate = transcriptionsDir.appendingPathComponent("\(baseName).\(tExt)")
                if fm.fileExists(atPath: candidate.path) {
                    transcriptURL = candidate
                    break
                }
            }

            // Try to parse title/date from frontmatter if transcript exists
            var title = baseName
            var date: Date?
            var duration = ""

            if let tURL = transcriptURL, tURL.pathExtension == "md",
               let content = try? String(contentsOf: tURL, encoding: .utf8) {
                let frontmatter = parseFrontmatter(content)
                if let t = frontmatter["title"] { title = t }
                if let d = frontmatter["duration"] { duration = d }
                if let dateStr = frontmatter["date"] {
                    let formatter = ISO8601DateFormatter()
                    date = formatter.date(from: dateStr)
                }
            }

            if date == nil {
                let attrs = try? fm.attributesOfItem(atPath: fileURL.path)
                date = attrs?[.creationDate] as? Date
            }

            results.append(RecordingEntry(
                id: baseName,
                title: title,
                date: date,
                duration: duration,
                type: type,
                transcriptionStatus: transcriptURL != nil ? .transcribed : .none,
                recordingURL: fileURL,
                transcriptURL: transcriptURL
            ))
        }

        entries = results.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private func parseFrontmatter(_ content: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = content.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return result }

        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "---" { break }
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                var value = parts[1].trimmingCharacters(in: .whitespaces)
                value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                result[key] = value
            }
        }
        return result
    }
}
