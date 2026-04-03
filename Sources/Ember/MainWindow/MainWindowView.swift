import SwiftUI

struct MainWindowView: View {
    @StateObject private var store = RecordingStore.shared
    @State private var selectedDateFilter: DateFilter = .all
    @State private var selectedTag: String?
    @State private var searchText = ""
    @State private var selectedRecording: Recording?
    @State private var showDeleteConfirmation = false
    @StateObject private var playbackState = PlaybackState()

    private var filteredRecordings: [Recording] {
        var results = store.recordings

        // Apply date filter
        if selectedDateFilter != .all {
            results = store.filter(dateFilter: selectedDateFilter)
        }

        // Apply tag filter
        if let tag = selectedTag {
            results = results.filter { $0.tags.contains(tag) }
        }

        // Apply search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            results = results.filter {
                $0.title.lowercased().contains(q) ||
                ($0.transcriptText?.lowercased().contains(q) ?? false)
            }
        }

        return results
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedDateFilter: $selectedDateFilter,
                selectedTag: $selectedTag,
                searchText: $searchText
            )
            .environmentObject(store)
        } content: {
            RecordingListView(
                recordings: filteredRecordings,
                selectedRecording: $selectedRecording,
                showDeleteConfirmation: $showDeleteConfirmation
            )
            .environmentObject(store)
        } detail: {
            if let recording = selectedRecording {
                DetailView(recording: binding(for: recording))
                    .environmentObject(store)
                    .environmentObject(playbackState)
                    .id(recording.id)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Select a recording")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Delete Recording?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let recording = selectedRecording {
                    store.delete(recording: recording)
                    selectedRecording = nil
                }
            }
        } message: {
            Text("This will delete the recording, transcript, and all associated data. This cannot be undone.")
        }
        .onAppear { store.scan() }
    }

    private func binding(for recording: Recording) -> Binding<Recording> {
        Binding(
            get: {
                store.recordings.first { $0.id == recording.id } ?? recording
            },
            set: { newValue in
                if let index = store.recordings.firstIndex(where: { $0.id == recording.id }) {
                    store.recordings[index] = newValue
                }
            }
        )
    }
}
