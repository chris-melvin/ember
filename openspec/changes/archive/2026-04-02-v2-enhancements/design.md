## Context

Ember v1 is a working macOS menu bar app that records video+audio, transcribes via whisper.cpp, and writes to an Obsidian vault. It's tightly coupled to Obsidian (wikilink syntax, "vault" terminology) and has a rigid recording flow (video-only, timestamp-only naming, no way to browse past recordings).

This change generalizes Ember for broader use while keeping Obsidian as the default happy path.

## Goals / Non-Goals

**Goals:**
- Make output folder configurable without Obsidian-specific language
- Keep Obsidian compatibility as default (frontmatter + wikilinks toggle)
- Add audio-only recording mode
- Post-recording title prompt for meaningful file naming
- In-app recording library for browsing and managing captures
- Configurable transcript output format (markdown, plain text, SRT)

**Non-Goals:**
- Full-featured media player (use QuickTime/Obsidian for playback)
- Tagging system or search beyond basic text matching
- Cloud sync or backup
- Editing transcripts within Ember

## Decisions

### 1. Output folder generalization

**Choice:** Rename all "vault" references to "output folder" in UI and code. Add an "Obsidian compatibility" toggle in preferences that controls wikilink generation. Frontmatter is always included in markdown output since it's useful regardless of Obsidian.

**Why:** Frontmatter (YAML metadata) is a universal markdown convention used by Hugo, Jekyll, Notion imports, etc. Wikilinks (`[[...]]`) are Obsidian-specific. Separating them lets non-Obsidian users get clean markdown while Obsidian users keep full linking.

**Default:** Obsidian compatibility ON (wikilinks enabled). New users who don't use Obsidian can toggle it off.

### 2. Title prompt as a sheet on the floating panel

**Choice:** When recording stops, replace the floating panel content with a title input field + "Save" / "Skip" buttons. Skip falls back to timestamp-only naming. The panel is already visible and positioned, so reusing it avoids spawning a new window.

**Why:** A separate dialog would steal focus and feel disruptive. Reusing the recording panel keeps the flow contained. "Skip" ensures fast users aren't blocked — the timestamp name is always valid.

**File naming with title:** `YYYY-MM-DD-HHmmss-slugified-title.mov` (e.g., `2026-04-02-083000-morning-thoughts.mov`). The slug is lowercase, spaces replaced with hyphens, special chars stripped.

### 3. Audio-only mode via toggle in menu bar

**Choice:** Add a submenu or toggle in the menu bar dropdown: "Record Video + Audio" / "Record Audio Only". Audio-only skips the camera entirely and outputs `.m4a`. The floating panel shows a minimal waveform/timer instead of camera preview.

**Why:** Menu bar toggle is the fastest access point — users switch modes before recording, not during. Audio-only is useful for voice notes, phone calls, or when camera isn't needed. `.m4a` is the standard Apple audio container (AAC codec), much smaller than video.

**Alternative considered:** Separate hotkeys for audio vs video. Rejected — too many shortcuts to remember.

### 4. Recording library as a full window

**Choice:** A proper NSWindow (not a popover) accessible from the menu bar dropdown. Shows a table/list of past recordings with: title, date, duration, type (video/audio), transcription status. Supports search by title, clicking opens the file in Finder/Obsidian, and delete with confirmation.

**Why:** A popover is too cramped for a list with search. The library is an occasional-use feature (not constant), so a full window is appropriate. It reads the output folder's `ember/recordings/` and `ember/transcriptions/` directories directly — no database needed.

**Data source:** Scan the filesystem. Parse frontmatter from transcript `.md` files for metadata. No separate database or index file.

### 5. Configurable output format

**Choice:** Add a "Transcript format" picker in preferences with three options:
- **Markdown** (default): YAML frontmatter + timestamped segments. Current behavior.
- **Plain text**: No frontmatter, no timestamps. Just the transcribed text.
- **SRT**: Standard subtitle format with sequence numbers, timestamps, and text. Useful for video editing.

**Why:** Different users need different formats. Markdown is the default for note-taking. SRT is standard for video workflows. Plain text is the simplest option.

All formats are written alongside the recording. The filename matches the recording but with the appropriate extension (`.md`, `.txt`, `.srt`).

## Risks / Trade-offs

**[Library performance with many files] → Mitigation:** Scanning hundreds of files on every library open could be slow. Mitigation: scan async, show results incrementally, cache the file list with filesystem watcher for updates.

**[Title slugification edge cases] → Mitigation:** Unicode, emoji, very long titles could produce bad filenames. Mitigation: strip to alphanumeric + hyphens, truncate to 60 chars, fall back to timestamp-only if slug is empty.

**[Breaking change for existing users] → Mitigation:** Renaming "vault" to "output folder" changes the UserDefaults key. Mitigation: migration code reads old `vaultPath` key and writes to new `outputFolderPath` key on first launch.
