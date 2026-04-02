## Why

Capturing thoughts by speaking is faster than typing, but existing tools (like SuperWhisper) focus on voice-to-text replacement rather than thought organization. We need a macOS-native app that records video+audio, transcribes locally via whisper.cpp, and deposits structured artifacts into an Obsidian vault — so recordings, transcripts, and notes all live together and link to each other.

## What Changes

- New macOS menu bar app built with Swift/SwiftUI
- Global hotkey to start/stop recording from anywhere
- Floating video preview window (NSPanel) during recording
- Video+audio capture via AVFoundation, saved as .mp4 to the vault's recordings folder
- Local transcription via whisper.cpp (compiled in-process), output as markdown to the vault's transcriptions folder
- Transcription markdown files include frontmatter and wikilinks back to the source recording
- Supports recordings from ~1 minute to several hours; long transcriptions run in the background
- Obsidian integration is file-based: write .md files and .mp4 files directly into the vault directory structure

## Capabilities

### New Capabilities
- `recording-capture`: Video+audio recording via AVFoundation with global hotkey trigger, floating preview, and file output to the vault
- `transcription`: Local speech-to-text using whisper.cpp, converting recorded audio to markdown transcripts with metadata and vault links
- `vault-integration`: File-based integration with Obsidian vaults — folder structure conventions, markdown formatting with frontmatter, and wikilinks between recordings and transcripts
- `app-shell`: macOS menu bar app shell — system tray presence, global hotkey registration, preferences (vault path, hotkey, whisper model), and app lifecycle

### Modified Capabilities

(none — greenfield project)

## Impact

- **Dependencies**: whisper.cpp (C/C++ compiled into Swift via bridging header), AVFoundation framework, Cocoa/AppKit for menu bar and NSPanel
- **System permissions**: Camera, microphone, accessibility (for global hotkey)
- **Storage**: Video files can be large (hundreds of MB for long sessions); stored in user's Obsidian vault
- **Build**: Xcode project with whisper.cpp source files included directly; whisper model files (~75-150MB) bundled or downloaded on first run
