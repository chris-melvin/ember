# Ember

A macOS menu bar app for recording your thoughts and getting them transcribed locally using [whisper.cpp](https://github.com/ggerganov/whisper.cpp).

Record video + audio or audio-only, and Ember transcribes it on your machine — no cloud, no API keys, no subscriptions. Transcripts are saved as Markdown (with Obsidian-compatible frontmatter), plain text, or SRT.

## Features

- **Local transcription** — whisper.cpp runs on-device with Metal acceleration
- **Video + Audio or Audio-only** — switch modes from the menu bar
- **Global hotkey** — Cmd+Shift+R to record from anywhere
- **Obsidian integration** — YAML frontmatter, wikilinks, direct vault output
- **Multiple formats** — Markdown, plain text, SRT subtitles
- **Recording library** — browse, search, and manage recordings
- **Title prompt** — name recordings after capture for organized file names
- **Whisper model selection** — base.en, base, medium.en, or large-v3-turbo

## Requirements

- macOS 14.0+
- Xcode 16+ (for building from source)
- Camera and microphone permissions
- Accessibility permission (for global hotkey)

## Install

### From DMG

Download the latest `.dmg` from [Releases](https://github.com/USER/ember/releases), open it, and drag Ember to Applications.

### From Source

```bash
# Clone with whisper.cpp submodule
git clone --recursive https://github.com/USER/ember.git
cd ember

# Generate Xcode project (requires xcodegen)
xcodegen generate

# Build release DMG
./scripts/build-release.sh
```

> **Note:** whisper.cpp must be pre-built. The static libraries are expected at `vendor/whisper.cpp/build-macos/`. See the [whisper.cpp build guide](https://github.com/ggerganov/whisper.cpp#build) for instructions.

## Usage

1. Launch Ember — it lives in your menu bar
2. Set your output folder in Preferences (Cmd+,)
3. A whisper model downloads automatically on first launch
4. Press **Cmd+Shift+R** to start recording
5. Press **Cmd+Shift+R** again (or click stop) to finish
6. Name the recording (optional) and transcription begins
7. Find your transcript in `<output folder>/ember/transcriptions/`

### Output structure

```
<output folder>/
  ember/
    recordings/
      2024-01-15-143022.mov
      2024-01-15-143022-my-idea.m4a
    transcriptions/
      2024-01-15-143022.md
      2024-01-15-143022-my-idea.md
```

### Transcript format (Markdown)

```markdown
---
title: "my idea"
date: 2024-01-15T14:30:22Z
duration: "2:34"
recording: "[[ember/recordings/2024-01-15-143022-my-idea.m4a]]"
tags: [ember/transcript]
---

[00:00] First segment of transcribed text.

[00:05] Second segment continues here.
```

## Building a Release

```bash
# Build with default version from project.yml
./scripts/build-release.sh

# Build with specific version
./scripts/build-release.sh 0.2.0
```

The DMG is created at `build/release/Ember-<version>.dmg`.

## Updating

After making changes:

```bash
# 1. Build new DMG
./scripts/build-release.sh 0.2.0

# 2. Replace the app
# Open the DMG and drag Ember to /Applications (replace existing)

# 3. (Optional) Create a GitHub release
gh release create v0.2.0 build/release/Ember-0.2.0.dmg --title "v0.2.0" --notes "What changed"
```

## Tech Stack

- **Swift / SwiftUI / AppKit** — native macOS
- **AVFoundation** — video and audio capture
- **whisper.cpp** — local speech-to-text (C/C++ via bridging header)
- **Metal** — GPU acceleration for transcription
- **XcodeGen** — project generation from `project.yml`

## License

MIT
