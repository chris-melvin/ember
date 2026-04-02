import SwiftUI
import AppKit

struct LibraryView: View {
    @StateObject private var scanner = LibraryScanner()
    @State private var searchText = ""
    @State private var selectedEntry: RecordingEntry?
    @State private var showDeleteConfirmation = false

    private var filteredEntries: [RecordingEntry] {
        if searchText.isEmpty { return scanner.entries }
        return scanner.entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search recordings...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.quaternary)

            Divider()

            if filteredEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(scanner.entries.isEmpty ? "No recordings yet" : "No matches")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredEntries, selection: $selectedEntry) { entry in
                    LibraryRow(entry: entry)
                        .tag(entry)
                        .onTapGesture(count: 2) {
                            revealInFinder(entry)
                        }
                        .contextMenu {
                            Button("Reveal in Finder") { revealInFinder(entry) }
                            Divider()
                            Button("Delete", role: .destructive) {
                                selectedEntry = entry
                                showDeleteConfirmation = true
                            }
                        }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 300)
        .onAppear { scanner.scan() }
        .alert("Delete Recording?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let entry = selectedEntry {
                    deleteEntry(entry)
                }
            }
        } message: {
            Text("This will delete the recording and its transcript. This cannot be undone.")
        }
    }

    private func revealInFinder(_ entry: RecordingEntry) {
        NSWorkspace.shared.activateFileViewerSelecting([entry.recordingURL])
    }

    private func deleteEntry(_ entry: RecordingEntry) {
        let fm = FileManager.default
        try? fm.removeItem(at: entry.recordingURL)
        if let transcriptURL = entry.transcriptURL {
            try? fm.removeItem(at: transcriptURL)
        }
        scanner.scan()
    }
}

struct LibraryRow: View {
    let entry: RecordingEntry

    var body: some View {
        HStack {
            Image(systemName: entry.type == .video ? "video.fill" : "mic.fill")
                .foregroundStyle(entry.type == .video ? .blue : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if let date = entry.date {
                        Text(LibraryView.dateFormatter.string(from: date))
                    }
                    if !entry.duration.isEmpty {
                        Text(entry.duration)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.transcriptionStatus.rawValue)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(entry.transcriptionStatus == .transcribed ? .green.opacity(0.2) : .gray.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 2)
    }
}

extension RecordingEntry: Hashable {
    static func == (lhs: RecordingEntry, rhs: RecordingEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
