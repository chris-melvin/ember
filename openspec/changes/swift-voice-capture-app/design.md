## Context

Ember is a greenfield macOS-native app for capturing thoughts via video+audio recording, with local transcription and Obsidian vault integration. The user records themselves speaking, whisper.cpp transcribes the audio locally, and the output (recording + transcript markdown) is deposited into an Obsidian vault where it integrates with the user's existing knowledge graph.

Target: macOS only (14+). Solo developer. Swift/SwiftUI stack. No server, no cloud, no LLM post-processing — just capture, transcribe, file.

## Goals / Non-Goals

**Goals:**
- Menu bar app with global hotkey to start/stop recording from anywhere
- Floating video preview during recording that doesn't steal focus
- Record video+audio via AVFoundation, output .mp4
- Transcribe audio locally using whisper.cpp compiled into the app
- Write recordings and transcripts into user-configured Obsidian vault paths
- Handle recordings from 1 minute to several hours gracefully

**Non-Goals:**
- Real-time / streaming transcription (transcribe after recording completes)
- LLM-based summarization or cleanup
- Obsidian plugin development (file-based integration only)
- Cross-platform support
- Audio-only recording mode (always captures video)
- Editing or playback within the app (Obsidian or QuickTime handle that)

## Decisions

### 1. Swift/SwiftUI over Electrobun/Electron

**Choice:** Native Swift app with SwiftUI for UI.

**Why:** Every core feature (menu bar, floating panel, global hotkey, AVFoundation recording, whisper.cpp integration) maps to a first-class macOS API. Electrobun lacks documented camera support and is still maturing. Electron adds 150MB+ of Chromium overhead. Swift gives us a ~5MB binary (excluding model), native Spaces behavior, and no webview quirks.

**Alternative considered:** Electrobun (Bun + system webview). Rejected due to undocumented camera/video capture, immature floating window behavior, and unnecessary abstraction layer for a macOS-only app.

### 2. whisper.cpp compiled in-process via bridging header

**Choice:** Include whisper.cpp C/C++ source files directly in the Xcode project. Call the C API from Swift through a bridging header.

**Why:** The whisper.cpp repo ships a working `whisper.swiftui` example. This approach gives us direct memory access, no IPC overhead, and the ability to use `whisper_full_parallel` for multi-core transcription of long recordings. No subprocess management needed.

**Alternative considered:** Shelling out to `whisper-cli` binary. Simpler integration but adds process management, stdout parsing, and loses access to progress callbacks and parallel processing.

### 3. Post-recording transcription (not real-time)

**Choice:** Transcribe only after the recording completes.

**Why:** Simplifies architecture significantly. No need for streaming audio buffers to whisper, no partial transcript UI, no synchronization. The user said they're fine waiting for long recordings. A 1-hour recording on Apple Silicon with the `base` model takes ~5-10 minutes.

**How it works:**
1. Recording stops → .mp4 saved to vault
2. Audio extracted to 16kHz 16-bit WAV (AVFoundation can do this directly)
3. whisper.cpp processes the WAV on a background thread
4. Progress shown in menu bar (percentage or spinner)
5. Transcript .md written to vault when done

### 4. File-based Obsidian integration

**Choice:** Write .md and .mp4 files directly to the vault directory. No Obsidian plugin.

**Why:** Obsidian watches its vault folder and picks up new files automatically. Wikilinks (`[[recording-name]]`) work natively. This keeps Ember completely decoupled from Obsidian — it just writes files in the right shape.

**Vault structure:**
```
<vault>/
  ember/
    recordings/
      2026-04-02-morning-thoughts.mp4
    transcriptions/
      2026-04-02-morning-thoughts.md
```

**Transcript markdown format:**
```markdown
---
title: Morning Thoughts
date: 2026-04-02T08:30:00
duration: "5:23"
recording: "[[ember/recordings/2026-04-02-morning-thoughts.mp4]]"
tags: [ember/transcript]
---

[Transcribed text here, segmented by whisper timestamps]
```

### 5. Floating NSPanel for video preview

**Choice:** Use `NSPanel` with `.floating` window level and `.nonactivating` style.

**Why:** NSPanel is purpose-built for auxiliary floating windows on macOS. It doesn't steal focus from the current app, respects Spaces, and can be positioned freely. A BrowserWindow in Electron/Electrobun would fight against all of these behaviors.

**Preview shows:** Camera feed + recording timer + stop button. Small and unobtrusive (picture-in-picture style).

### 6. Global hotkey via NSEvent + Accessibility

**Choice:** Register a global hotkey using `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` combined with a configurable key combination.

**Why:** Native macOS API, no third-party dependency needed. Requires Accessibility permission which the app requests on first launch.

**Default hotkey:** Configurable in preferences. Suggested default: `⌘+Shift+R`.

### 7. Whisper model management

**Choice:** Bundle the `ggml-base.en` model (~150MB) with the app. Allow downloading larger models from preferences.

**Why:** The base English model is a good default — fast enough for real-time factor <0.5x on Apple Silicon, good accuracy for single-speaker dictation. Users who want better accuracy can download `medium` or `large` models.

**Models stored at:** `~/Library/Application Support/Ember/Models/`

## Risks / Trade-offs

**[Large video files] → Mitigation:** Long recordings produce large .mp4 files (potentially GBs). Obsidian may struggle with very large vaults. Mitigation: document recommended vault backup strategy; consider offering a separate recordings path outside the vault with symlinks.

**[whisper.cpp accuracy] → Mitigation:** Whisper base model has decent but imperfect accuracy, especially for non-English or accented speech. Mitigation: user can download larger models; transcripts are meant to be reference material alongside the raw recording, not final documents.

**[Accessibility permission UX] → Mitigation:** Global hotkey requires Accessibility access, which macOS gates behind System Settings. Users may not understand why. Mitigation: clear onboarding flow explaining why the permission is needed, with a direct link to the settings pane.

**[Long transcription times] → Mitigation:** A 3-hour recording could take 15-30+ minutes to transcribe. Mitigation: background processing with progress indicator in menu bar; user can continue working and gets a notification when done.

**[Camera privacy] → Mitigation:** Always-available camera recording is sensitive. Mitigation: clear recording indicator (menu bar icon change + floating preview), no background recording without explicit user action.
