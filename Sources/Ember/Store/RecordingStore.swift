import Foundation
import Combine

enum DateFilter: String, CaseIterable, Identifiable {
    case all = "All Recordings"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"

    var id: String { rawValue }
}

class RecordingStore: ObservableObject {
    @Published var recordings: [Recording] = []

    static let shared = RecordingStore()

    private let fm = FileManager.default
    private let metadataDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let metadataEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private var emberDir: URL? {
        guard let path = UserDefaults.standard.string(forKey: "outputFolderPath"), !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("ember", isDirectory: true)
    }

    // MARK: - Scanning

    func scan() {
        guard let emberDir else {
            recordings = []
            return
        }

        guard let contents = try? fm.contentsOfDirectory(
            at: emberDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            recordings = []
            return
        }

        var results: [Recording] = []

        for folderURL in contents {
            guard isDirectory(folderURL) else { continue }

            let metadataURL = folderURL.appendingPathComponent("metadata.json")
            guard fm.fileExists(atPath: metadataURL.path),
                  let data = try? Data(contentsOf: metadataURL),
                  let metadata = try? metadataDecoder.decode(RecordingMetadata.self, from: data) else {
                continue
            }

            let transcriptURL = folderURL.appendingPathComponent("transcript.md")
            let transcriptText: String? = try? String(contentsOf: transcriptURL, encoding: .utf8)

            let recording = Recording(
                id: folderURL.lastPathComponent,
                title: metadata.title,
                createdAt: metadata.createdAt,
                duration: metadata.duration,
                type: metadata.type,
                tags: metadata.tags,
                transcriptionStatus: metadata.transcriptionStatus,
                editedAt: metadata.editedAt,
                folderURL: folderURL,
                transcriptText: transcriptText
            )
            results.append(recording)
        }

        recordings = results.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Search

    func search(query: String) -> [Recording] {
        guard !query.isEmpty else { return recordings }
        let q = query.lowercased()
        return recordings.filter { recording in
            recording.title.lowercased().contains(q) ||
            (recording.transcriptText?.lowercased().contains(q) ?? false)
        }
    }

    // MARK: - Filtering

    func filter(tag: String) -> [Recording] {
        recordings.filter { $0.tags.contains(tag) }
    }

    func filter(dateFilter: DateFilter) -> [Recording] {
        let calendar = Calendar.current
        let now = Date()
        switch dateFilter {
        case .all:
            return recordings
        case .today:
            return recordings.filter { calendar.isDateInToday($0.createdAt) }
        case .thisWeek:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return recordings }
            return recordings.filter { $0.createdAt >= weekStart }
        case .thisMonth:
            guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return recordings }
            return recordings.filter { $0.createdAt >= monthStart }
        }
    }

    // MARK: - Tag Aggregation

    var allTags: [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        for recording in recordings {
            for tag in recording.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts.map { (tag: $0.key, count: $0.value) }.sorted { $0.tag < $1.tag }
    }

    // MARK: - Date Group Counts

    func count(for dateFilter: DateFilter) -> Int {
        filter(dateFilter: dateFilter).count
    }

    // MARK: - Metadata Persistence

    func saveMetadata(for recording: Recording) {
        guard let data = try? metadataEncoder.encode(recording.metadata) else { return }
        try? data.write(to: recording.metadataURL, options: .atomic)

        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
        }
    }

    func saveTranscript(_ text: String, for recording: Recording) {
        try? text.write(to: recording.transcriptURL, atomically: true, encoding: .utf8)

        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index].transcriptText = text
            recordings[index].editedAt = Date()
            saveMetadata(for: recordings[index])
        }
    }

    // MARK: - CRUD

    func createRecordingFolder(timestamp: String, slug: String?) -> URL? {
        guard let emberDir else { return nil }

        var folderName = timestamp
        if let slug, !slug.isEmpty {
            folderName += "-\(slug)"
        }

        var folderURL = emberDir.appendingPathComponent(folderName, isDirectory: true)

        // Handle duplicate timestamps
        if fm.fileExists(atPath: folderURL.path) {
            var suffix = 2
            while fm.fileExists(atPath: folderURL.path) {
                let name = slug.map { "\(timestamp)-\($0)-\(suffix)" } ?? "\(timestamp)-\(suffix)"
                folderURL = emberDir.appendingPathComponent(name, isDirectory: true)
                suffix += 1
            }
        }

        try? fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL
    }

    func writeInitialMetadata(to folderURL: URL, title: String?, type: RecordingMetadata.RecordingType) {
        let metadata = RecordingMetadata(
            title: title ?? folderURL.lastPathComponent,
            createdAt: Date(),
            duration: 0,
            type: type,
            tags: [],
            transcriptionStatus: .pending,
            editedAt: nil
        )
        let metadataURL = folderURL.appendingPathComponent("metadata.json")
        if let data = try? metadataEncoder.encode(metadata) {
            try? data.write(to: metadataURL, options: .atomic)
        }
    }

    func delete(recording: Recording) {
        try? fm.removeItem(at: recording.folderURL)
        recordings.removeAll { $0.id == recording.id }
    }

    // MARK: - Helpers

    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}
