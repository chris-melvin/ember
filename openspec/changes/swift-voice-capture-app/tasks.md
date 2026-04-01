## 1. Project Setup

- [x] 1.1 Create Xcode project as macOS app with SwiftUI lifecycle, set to menu bar only (LSUIElement = YES, no Dock icon)
- [x] 1.2 Add whisper.cpp source files to the project with a C bridging header for Swift interop
- [x] 1.3 Bundle the `ggml-base.en.bin` whisper model in the app resources (or download on first launch to `~/Library/Application Support/Ember/Models/`)
- [x] 1.4 Configure Info.plist with camera and microphone usage descriptions, and Accessibility usage if needed

## 2. App Shell — Menu Bar & Lifecycle

- [x] 2.1 Implement NSStatusItem with icon in menu bar (idle, recording, transcribing states)
- [x] 2.2 Build dropdown menu: start/stop recording, transcription queue status, preferences, quit
- [x] 2.3 Implement global hotkey registration using NSEvent.addGlobalMonitorForEvents (default: Cmd+Shift+R)
- [x] 2.4 Add Accessibility permission check and onboarding prompt on first launch
- [x] 2.5 Implement launch-at-login using SMAppService (macOS 13+)

## 3. Recording Capture

- [x] 3.1 Set up AVCaptureSession with video (default camera) and audio (default mic) inputs
- [x] 3.2 Implement AVCaptureMovieFileOutput to write .mp4 to vault recordings folder with timestamp naming (YYYY-MM-DD-HHmmss.mp4)
- [x] 3.3 Build floating NSPanel with camera preview layer, elapsed timer, and stop button — non-activating, floating window level
- [x] 3.4 Wire start/stop recording to global hotkey and preview panel stop button
- [x] 3.5 Create vault folder structure (ember/recordings/, ember/transcriptions/) on first recording if not present

## 4. Transcription

- [x] 4.1 Implement audio extraction from .mp4 to 16kHz 16-bit WAV using AVFoundation (AVAssetReader + AVAssetWriter)
- [x] 4.2 Create Swift wrapper around whisper.cpp C API (init model, run whisper_full / whisper_full_parallel, extract segments)
- [x] 4.3 Run transcription on a background thread with progress reporting via whisper callbacks
- [x] 4.4 Generate markdown transcript with YAML frontmatter (title, date, duration, recording wikilink, tags) and timestamped text segments
- [x] 4.5 Write transcript .md file to vault transcriptions folder

## 5. Vault Integration

- [x] 5.1 Implement vault path configuration with directory picker, persisted in UserDefaults
- [x] 5.2 First-launch onboarding flow: prompt user to select vault directory
- [x] 5.3 Validate vault path exists on each recording start; show error if missing

## 6. Preferences

- [x] 6.1 Build preferences window with: vault path selector, global hotkey configuration, whisper model picker, video quality setting
- [x] 6.2 Implement whisper model management: list available models, download additional models, select active model
- [x] 6.3 Implement launch-at-login toggle wired to SMAppService

## 7. Notifications & Status

- [x] 7.1 Update menu bar icon state during recording and transcription
- [x] 7.2 Show macOS notification when transcription completes with transcript title
- [x] 7.3 Display transcription queue/progress in menu bar dropdown
