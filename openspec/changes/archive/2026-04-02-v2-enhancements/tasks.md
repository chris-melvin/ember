## 1. Output Folder Generalization

- [x] 1.1 Rename `vaultPath` UserDefaults key to `outputFolderPath` with migration: read old key on launch, write to new key, remove old
- [x] 1.2 Rename all "vault" references in UI strings and code to "output folder"
- [x] 1.3 Add `obsidianCompatibility` bool toggle to UserDefaults (default: true)
- [x] 1.4 Update TranscriptionManager to use relative path (`../recordings/`) when Obsidian compatibility is off, wikilink when on

## 2. Configurable Transcript Format

- [x] 2.1 Add `transcriptFormat` enum (markdown, plainText, srt) to UserDefaults with markdown as default
- [x] 2.2 Implement plain text transcript writer: transcribed text only, no frontmatter, `.txt` extension
- [x] 2.3 Implement SRT transcript writer: sequential numbering, `HH:MM:SS,mmm --> HH:MM:SS,mmm` timestamps, `.srt` extension
- [x] 2.4 Refactor TranscriptionManager.writeTranscriptMarkdown to dispatch to the correct writer based on format setting
- [x] 2.5 Add transcript format picker to PreferencesView

## 3. Title Prompt

- [x] 3.1 Create title slugification function: lowercase, replace spaces with hyphens, strip non-alphanumeric, truncate to 60 chars at word boundary
- [x] 3.2 Create TitlePromptView (SwiftUI): text field, Save button, Skip button
- [x] 3.3 Integrate title prompt into RecordingPreviewPanel: on stop, transition panel content from recording controls to TitlePromptView
- [x] 3.4 Update AppDelegate stop flow: wait for title before saving files; rename temp recording file to final name with slug
- [x] 3.5 Update TranscriptionManager to accept and use the user-provided title in frontmatter

## 4. Audio-Only Mode

- [x] 4.1 Add `recordingMode` enum (videoAndAudio, audioOnly) to RecordingManager, persisted in UserDefaults
- [x] 4.2 Implement audio-only capture path in RecordingManager: skip video input, use AVCaptureAudioFileOutput or AVAssetWriter for `.m4a` output
- [x] 4.3 Create AudioOnlyPanelContent view: audio level indicator, elapsed timer, stop button (no camera preview)
- [x] 4.4 Update RecordingPreviewPanel to show AudioOnlyPanelContent when in audio-only mode
- [x] 4.5 Update TranscriptionManager to handle `.m4a` input (extract audio directly, skip video demux)
- [x] 4.6 Skip camera permission request when in audio-only mode

## 5. Recording Library

- [x] 5.1 Create RecordingEntry model: title, date, duration, type (video/audio), transcriptionStatus, recordingURL, transcriptURL
- [x] 5.2 Create LibraryScanner: scan output folder's ember/recordings/ and ember/transcriptions/, parse frontmatter from .md files, build RecordingEntry list
- [x] 5.3 Create LibraryView (SwiftUI): table/list of RecordingEntry items with columns for title, date, duration, type, status
- [x] 5.4 Add search field to LibraryView that filters entries by title/filename
- [x] 5.5 Implement double-click to reveal recording in Finder (NSWorkspace.shared.activateFileViewerSelecting)
- [x] 5.6 Implement delete with confirmation dialog: remove recording file + associated transcript
- [x] 5.7 Create LibraryWindow managed by AppDelegate, opened from menu bar dropdown

## 6. Menu Bar & Preferences Updates

- [x] 6.1 Add recording mode submenu to StatusBarController dropdown: "Video + Audio" / "Audio Only" with checkmark on active mode
- [x] 6.2 Add "Library" menu item to StatusBarController dropdown
- [x] 6.3 Add Obsidian compatibility toggle to PreferencesView
- [x] 6.4 Add output folder path selector (replacing vault path) to PreferencesView
