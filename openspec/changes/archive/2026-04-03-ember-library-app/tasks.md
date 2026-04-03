## 1. Data Model & Storage Layer

- [x] 1.1 Create `Recording` model struct with fields: id, title, createdAt, duration, type (video/audio), tags, transcriptionStatus, editedAt, folderURL, transcriptText
- [x] 1.2 Create `RecordingStore` ObservableObject class with scan(), search(query:), filter(tag:), filter(dateRange:), save(metadata:for:), delete(recording:) methods
- [x] 1.3 Implement folder scanning in RecordingStore — read all `ember/*/metadata.json` files and build in-memory array of Recording models
- [x] 1.4 Implement transcript content loading — read `transcript.md` from each recording folder for search indexing
- [x] 1.5 Implement metadata.json read/write helpers — encode/decode metadata.json with Codable
- [x] 1.6 Implement tag aggregation — collect unique tags with counts from all recordings

## 2. Co-located Storage Format

- [x] 2.1 Update AppDelegate.startRecording to create co-located folder (`ember/<timestamp>-<slug>/`) and write recording as `recording.<ext>`
- [x] 2.2 Update TranscriptionManager to write transcript as clean timestamped markdown (no YAML frontmatter) to `transcript.md` inside the recording folder
- [x] 2.3 Update TranscriptionManager to create/update `metadata.json` with title, createdAt, duration, type, tags, transcriptionStatus
- [x] 2.4 Remove YAML frontmatter generation, Obsidian wikilink logic, and SRT/plain text transcript writers from TranscriptionManager
- [x] 2.5 Remove transcript format selection and Obsidian compatibility toggle from PreferencesView

## 3. Storage Migration

- [x] 3.1 Create `StorageMigrator` class that detects old format (media files directly in `ember/recordings/`)
- [x] 3.2 Implement migration logic — for each recording: create folder, move media as `recording.<ext>`, parse frontmatter from transcript, generate metadata.json, strip frontmatter and save as `transcript.md`
- [x] 3.3 Add migration dialog on app launch — show pre-migration confirmation and post-migration summary
- [x] 3.4 Handle migration edge cases — missing transcripts, duplicate timestamps, file permission errors, partial failures

## 4. Main Window Shell

- [x] 4.1 Create `MainWindowController` that opens/manages the main NSWindow with NavigationSplitView content
- [x] 4.2 Create `SidebarView` with sections: date filters (All, Today, This Week, This Month), Tags list with counts, and search field
- [x] 4.3 Create `RecordingListView` showing filtered/sorted recording entries with title, date, duration, type icon, and transcription badge
- [x] 4.4 Create `DetailView` as the right-hand pane — placeholder layout with playback area, transcript area, and tag editor area
- [x] 4.5 Create `BottomStatusBar` view showing recording state (idle/recording/transcribing), mode selector, and hotkey hint
- [x] 4.6 Wire main window to open from menu bar "Library" action and Cmd+L

## 5. Playback

- [x] 5.1 Create `PlaybackState` ObservableObject with currentTime, duration, isPlaying, and seekTo properties
- [x] 5.2 Create `VideoPlayerView` using AVPlayerView wrapped in NSViewRepresentable for video recordings
- [x] 5.3 Create `AudioPlayerView` with seek bar and transport controls (play/pause, time display) for audio recordings
- [x] 5.4 Create `PlayerContainerView` that switches between VideoPlayerView and AudioPlayerView based on recording type
- [x] 5.5 Implement AVPlayer setup with addPeriodicTimeObserver (100ms interval) publishing to PlaybackState
- [x] 5.6 Implement playback position persistence — store last position per recording ID in a session dictionary

## 6. Transcript Sync & Display

- [x] 6.1 Create `TranscriptSegment` model — parse `[MM:SS]` and `[HH:MM:SS]` timestamps from transcript lines into structured segments with startTime and text
- [x] 6.2 Create `TranscriptView` displaying parsed segments with clickable timestamps
- [x] 6.3 Implement highlight sync — observe PlaybackState.currentTime and highlight the active segment based on timestamp ranges
- [x] 6.4 Implement auto-scroll — scroll transcript to keep active segment visible during playback
- [x] 6.5 Implement click-to-seek — clicking a timestamp sets PlaybackState.seekTo which the player observes

## 7. Transcript Editing

- [x] 7.1 Make TranscriptView segments editable inline using TextEditor per segment (timestamps non-editable)
- [x] 7.2 Implement debounced auto-save (500ms) — write edited segments back to transcript.md preserving timestamp format
- [x] 7.3 Update metadata.json editedAt field on transcript save
- [x] 7.4 Ensure undo/redo works via standard SwiftUI UndoManager integration

## 8. Search & Filtering

- [x] 8.1 Implement RecordingStore.search(query:) — case-insensitive match against title and transcript content
- [x] 8.2 Wire search field in SidebarView to RecordingStore search, updating the recording list
- [x] 8.3 Implement date range filtering — filter by Today, This Week, This Month using Calendar calculations
- [x] 8.4 Implement tag filtering — filter recording list by selected tag from sidebar
- [x] 8.5 Combine filters — search query + date filter + tag filter stack together

## 9. Tagging

- [x] 9.1 Create `TagEditorView` in detail view — display current tags as chips, text field to add new tag, remove button per tag
- [x] 9.2 Wire tag add/remove to RecordingStore — update metadata.json tags array and refresh in-memory cache
- [x] 9.3 Wire sidebar tag list — display aggregated tags with counts, tap to filter

## 10. Integration & Cleanup

- [x] 10.1 Extract recording coordination logic from AppDelegate into `RecordingCoordinator` ObservableObject — owns RecordingManager + TranscriptionManager, publishes app state
- [x] 10.2 Update StatusBarController to observe RecordingCoordinator instead of AppDelegate directly
- [x] 10.3 Update main window BottomStatusBar to observe RecordingCoordinator for recording/transcribing state
- [x] 10.4 Ensure new recordings trigger RecordingStore refresh so library updates immediately
- [x] 10.5 Remove old LibraryView, LibraryScanner, RecordingEntry, and LibraryRow code
- [x] 10.6 Update delete flow — deleting a recording removes the entire co-located folder
- [x] 10.7 Test migration path with sample old-format recordings
