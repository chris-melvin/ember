## MODIFIED Requirements

### Requirement: Automatic transcription after recording
The system SHALL automatically begin transcribing the audio from a completed recording using whisper.cpp running locally in-process.

#### Scenario: Transcription starts after recording completes
- **WHEN** a recording is saved to the output folder
- **THEN** the system extracts audio as 16kHz 16-bit WAV and begins whisper.cpp transcription on a background thread

#### Scenario: App remains responsive during transcription
- **WHEN** transcription is in progress
- **THEN** the user can start new recordings, browse the library, and interact with the app without interruption

### Requirement: Transcript output as clean markdown
The system SHALL write the completed transcript as a clean timestamped markdown file inside the recording's co-located folder.

#### Scenario: Transcript file created
- **WHEN** transcription completes for a recording in folder `ember/2024-01-15-143022-standup/`
- **THEN** the system creates `ember/2024-01-15-143022-standup/transcript.md` containing timestamped segments in `[MM:SS] text` format without YAML frontmatter

#### Scenario: Metadata updated after transcription
- **WHEN** transcription completes
- **THEN** the recording's `metadata.json` `transcriptionStatus` is set to "completed" and `duration` is populated

### Requirement: Transcription progress indication
The system SHALL indicate transcription progress in the menu bar and main window.

#### Scenario: Progress shown during transcription
- **WHEN** transcription is running
- **THEN** the menu bar icon shows a progress indicator and the main window bottom bar shows transcription status

#### Scenario: Completion notification
- **WHEN** transcription completes
- **THEN** the system sends a macOS notification with the recording title

### Requirement: Whisper model selection
The system SHALL allow the user to select which whisper model to use for transcription.

#### Scenario: Default model
- **WHEN** the app is launched for the first time
- **THEN** the `ggml-base.en` model is downloaded and used for transcription

#### Scenario: User changes model
- **WHEN** the user selects a different model in preferences
- **THEN** subsequent transcriptions use the selected model
