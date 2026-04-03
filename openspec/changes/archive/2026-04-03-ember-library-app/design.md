## Context

Ember is a macOS menu-bar app that records audio/video and transcribes using whisper.cpp. Currently it stores recordings in `ember/recordings/` and transcripts in `ember/transcriptions/` as flat files with YAML frontmatter. The library is a basic SwiftUI list that reveals files in Finder.

The app is built with SwiftUI + AppKit (NSPanel, NSWindow), uses AVFoundation for capture, and whisper.cpp via a bridging header for transcription. Key managers: `RecordingManager` (capture), `TranscriptionManager` (whisper pipeline), `LibraryScanner` (disk scan), `StatusBarController` (menu bar). State flows through `AppDelegate`.

## Goals / Non-Goals

**Goals:**
- Full main window with sidebar navigation, recording list, and detail view with playback + transcript
- Co-located per-recording folder storage with metadata.json
- In-app audio/video playback synced to transcript timestamps
- Inline transcript editing
- Full-text search across titles and transcript content
- Tag-based organization
- Automatic migration from old folder layout
- Keep menu bar for hotkey recording and quick access

**Non-Goals:**
- Database/Core Data/SwiftData (files-only for now)
- Cloud sync or iCloud integration
- Transcript re-generation or re-transcription
- Multiple whisper model comparison
- Video editing or trimming
- Export/share functionality
- Obsidian or any external tool integration

## Decisions

### 1. Main window architecture: NavigationSplitView with three columns

Use SwiftUI `NavigationSplitView` with sidebar (filters + tags), content (recording list), and detail (playback + transcript).

**Why:** This is the standard macOS pattern (Mail, Notes, Voice Memos). SwiftUI provides this natively with proper resizing, keyboard navigation, and platform behavior. A two-column split would cram too much into the sidebar.

**Alternative considered:** Single-column list + sheet for detail. Rejected — doesn't feel like a "real app" and loses the always-visible library.

### 2. Data layer: RecordingStore as ObservableObject with in-memory cache

A single `RecordingStore` class replaces `LibraryScanner`. On init, it scans all co-located folders, reads `metadata.json` + transcript text, and builds an in-memory array of `Recording` models. All filtering, search, and tag operations run against this cache. Mutations (edit transcript, add tag) write to disk immediately and update the cache.

**Why:** Files as source of truth keeps data portable and transparent. In-memory cache is fast enough for hundreds of recordings. No schema migration complexity.

**Alternative considered:** SwiftData with file-backed storage. Rejected — introduces a second source of truth, and the user values being able to browse recordings in Finder.

### 3. Storage format: Co-located folders with metadata.json

Each recording lives in its own timestamped folder:
```
ember/
└── 2024-01-15-143022-standup/
    ├── recording.mov          # media file (generic name, extension varies)
    ├── transcript.md          # clean markdown, no frontmatter
    └── metadata.json          # title, tags, duration, dates, type
```

The folder name serves as the recording ID. Inside, files have generic names (`recording.*`, `transcript.md`) so the folder is self-contained.

**Why:** Co-location makes each recording a portable unit. Generic filenames inside avoid duplication of the slug. metadata.json is simpler to parse than YAML frontmatter and easy to extend.

**Alternative considered:** Keep flat folders with linked filenames. Rejected — the user specifically identified the split folders as a pain point at scale.

**metadata.json schema:**
```json
{
  "title": "Standup Notes",
  "createdAt": "2024-01-15T14:30:22Z",
  "duration": 154.2,
  "type": "video",
  "tags": ["work", "standup"],
  "transcriptionStatus": "completed",
  "editedAt": null
}
```

### 4. Transcript format: Clean timestamped markdown

Transcripts are plain markdown with timestamp prefixes, no YAML frontmatter:
```markdown
[00:00] So for today's standup, I wanted to talk about...

[00:15] The main blocker right now is the API integration...
```

**Why:** Removing frontmatter makes transcripts easier to read and edit. Metadata lives in `metadata.json`. The `[MM:SS]` format is human-readable and easily parseable for sync.

### 5. Playback: AVPlayer with periodic time observer

Use `AVPlayer` wrapped in a SwiftUI view. For video recordings, show video; for audio, show a waveform or simple seek bar. A `addPeriodicTimeObserver` fires every 100ms and publishes the current timestamp to drive transcript highlighting.

**Why:** AVPlayer handles both audio and video uniformly. The periodic observer is the standard approach for media sync. 100ms granularity is smooth enough for transcript highlighting without excessive CPU.

**Alternative considered:** AVAudioPlayer for audio. Rejected — AVPlayer handles both formats, reducing code paths.

### 6. Transcript sync: Bidirectional via shared playback state

A shared `PlaybackState` (ObservableObject) holds `currentTime`, `isPlaying`, and `seekTo`. The player publishes `currentTime`; the transcript view observes it to highlight the active segment. Clicking a timestamp in the transcript sets `seekTo`, which the player observes.

**Why:** Decoupling via shared state means the player and transcript views don't reference each other directly. Easy to test each in isolation.

### 7. Search: In-memory string matching

`RecordingStore.search(query:)` filters recordings where the title OR any line of the transcript content contains the query (case-insensitive). Transcript text is loaded into memory during the initial scan.

**Why:** Simple, zero-dependency, fast enough for the first few hundred recordings. The entire transcript corpus for 500 recordings of ~5 minutes each is roughly 5-10 MB of text — trivial to hold in memory.

**Alternative considered:** macOS SearchKit / CSSearchableIndex. Deferred — overkill for current scale, can be added later if needed.

### 8. Inline transcript editing: TextEditor with auto-save

The transcript view uses a SwiftUI `TextEditor` that's always editable. Changes debounce (500ms) and auto-save to `transcript.md`. The `metadata.json` `editedAt` field is updated on save.

**Why:** No edit mode toggle means one fewer interaction. Debounced auto-save prevents data loss without constant disk writes.

**Alternative considered:** Explicit edit mode with save button. Rejected — user preferred inline editing.

### 9. Tags: Flat string array in metadata.json

Tags are stored as `["work", "standup"]` in each recording's `metadata.json`. The sidebar aggregates all unique tags with counts. Clicking a tag filters the list. Adding/removing tags happens in the detail view.

**Why:** Flat strings are the simplest model. No tag management UI needed — tags are created by typing them and removed by deleting them. Aggregation happens at scan time.

### 10. Menu bar + main window coexistence

The menu bar retains its current role: hotkey recording, mode toggle, quick access. The main window is the primary interface for browsing. `StatusBarController` and the main window both observe `RecordingCoordinator` (extracted from AppDelegate) for recording state.

**Why:** The hotkey-to-record workflow is the core of Ember. The main window adds the library experience without replacing what works.

## Risks / Trade-offs

**[Risk] In-memory transcript loading is slow with many large recordings**
Mitigation: Lazy-load transcript content. Load metadata.json eagerly (small), load transcript text on-demand or in background after initial scan. Search only covers loaded transcripts — show a "loading..." state if scan isn't complete.

**[Risk] Migration corrupts or loses existing recordings**
Mitigation: Migration creates new co-located folders and copies/moves files. If the old structure is detected, migrate on first launch with a progress indicator. Keep old folders until migration completes successfully. Log any failures for user review.

**[Risk] TextEditor performance with very long transcripts**
Mitigation: For transcripts over ~50KB, consider switching to a non-editable `Text` view with an "Edit" button that opens a focused editor. This is an optimization that can come later.

**[Risk] AVPlayer video in SwiftUI has rough edges on macOS**
Mitigation: Use `AVPlayerView` wrapped in `NSViewRepresentable` for reliable video playback. Audio-only can use a simpler custom view with just transport controls.

**[Trade-off] Files-only means slower queries at scale**
Accepted: For the target scale (tens to low hundreds of recordings), file scanning is fast enough. If Ember grows to thousands of recordings, a SQLite index can be added behind `RecordingStore` without changing the public API.

**[Trade-off] Dropping Obsidian integration**
Accepted: This simplifies the storage model significantly. Users who want Obsidian integration can point Obsidian at the ember folder — markdown transcripts are still readable, just not formatted with wikilinks.

## Migration Plan

1. On app launch, check if old-format folders exist (`ember/recordings/` with files directly inside, not subfolders)
2. Show a migration dialog: "Ember needs to reorganize your recordings. This is a one-time operation."
3. For each recording file in `ember/recordings/`:
   a. Create folder `ember/<basename>/`
   b. Move recording to `ember/<basename>/recording.<ext>`
   c. Find matching transcript in `ember/transcriptions/<basename>.{md,txt,srt}`
   d. Parse YAML frontmatter if present, convert to `metadata.json`
   e. Strip frontmatter from transcript, save as `ember/<basename>/transcript.md`
   f. If no transcript exists, create metadata.json with `transcriptionStatus: "none"`
4. After all files migrated, remove empty `ember/recordings/` and `ember/transcriptions/` directories
5. If any file fails to migrate, log it and continue with remaining files
6. Show completion summary

**Rollback:** Since we move files (not delete), a failed migration leaves originals in place. The app can detect mixed state and offer to retry.
