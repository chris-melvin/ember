## Why

Ember is currently a menu-bar utility that records, transcribes, and drops files into separate folders. As recordings accumulate, the split between `recordings/` and `transcriptions/` makes it hard to find and manage content. The basic library view only reveals files in Finder — there's no playback, no transcript viewing, no search across content. To be useful long-term, Ember needs to become a real app: a browsable library with in-app playback, synced transcripts, full-text search, and organized storage — like Apple Voice Memos but with transcription built in.

## What Changes

- **Main window with sidebar + detail view**: A full `NavigationSplitView` layout with date-grouped recording list, tag filters, search, and a detail pane showing playback and transcript
- **In-app playback**: AVPlayer-based audio/video playback with seek bar, embedded in the detail view
- **Transcript synchronization**: Clicking a timestamp seeks the player; playback highlights the current transcript segment
- **Inline transcript editing**: Edit transcripts directly in the detail view
- **Full-text search**: Search across recording titles and transcript content
- **Tagging system**: Add/remove tags on recordings, filter by tag in sidebar
- **Co-located storage**: Each recording gets its own folder containing `recording.*`, `transcript.md`, and `metadata.json` — replaces the split `recordings/` + `transcriptions/` layout
- **Storage migration**: One-time migration from old folder structure to new co-located format on first launch
- **Drop Obsidian integration**: Remove wikilink formatting, Obsidian compatibility toggle, and YAML frontmatter from transcripts — transcripts become clean timestamped markdown
- **Drop transcript format selection**: Standardize on clean markdown (no more SRT/plain text options)
- **Menu bar retained**: Hotkey recording and quick controls stay in the menu bar; main window is for browsing and playback

## Capabilities

### New Capabilities
- `co-located-storage`: Per-recording folder structure with `recording.*`, `transcript.md`, and `metadata.json`; replaces split folders and YAML frontmatter
- `storage-migration`: One-time migration from old `recordings/` + `transcriptions/` layout to co-located folders
- `playback`: In-app audio/video playback with seek bar and transport controls
- `transcript-sync`: Bidirectional sync between player position and transcript — highlight current segment, click timestamp to seek
- `transcript-editing`: Inline editing of transcript text in the detail view
- `full-text-search`: Search across recording titles and full transcript content
- `tagging`: Add/remove tags on recordings; filter recordings by tag in sidebar

### Modified Capabilities
- `app-shell`: Add main window with `NavigationSplitView` (sidebar + detail); menu bar becomes secondary control surface for recording
- `recording-library`: Complete redesign — sidebar with date groups, tag filters, and recording list; detail view with playback, transcript, and metadata; replaces current flat list + Finder reveal
- `output-configuration`: Remove Obsidian compatibility toggle and transcript format selection; output folder config remains
- `transcription`: Transcript output changes from YAML-frontmatter markdown to clean timestamped markdown written to co-located folder; remove SRT and plain text formats
- `recording-capture`: Recording initiated from menu bar writes to new co-located folder structure

## Impact

- **UI layer**: LibraryView, LibraryScanner, LibraryRow replaced with new NavigationSplitView-based main window (sidebar, list, detail with playback + transcript)
- **Data layer**: New `RecordingStore` replaces `LibraryScanner` — scans co-located folders, builds in-memory index, supports search/filter/CRUD
- **Storage format**: Every recording becomes a folder (`timestamp-slug/`) containing media, transcript, and metadata.json — breaking change from flat file layout
- **Migration**: Existing users need automatic migration of old files on first launch
- **Removed code**: Obsidian wikilink logic, transcript format selection (SRT/plain text writers), YAML frontmatter generation/parsing
- **Dependencies**: No new external dependencies — AVPlayer, AVFoundation, SwiftUI already available
- **Preferences**: Simplified — remove Obsidian toggle and transcript format picker
