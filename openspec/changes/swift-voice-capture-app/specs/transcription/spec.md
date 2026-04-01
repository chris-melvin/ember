## ADDED Requirements

### Requirement: Automatic transcription after recording
The system SHALL automatically begin transcribing the audio from a completed recording using whisper.cpp running locally in-process.

#### Scenario: Transcription starts after recording completes
- **WHEN** a recording is saved to the vault
- **THEN** the system extracts audio as 16kHz 16-bit WAV and begins whisper.cpp transcription on a background thread

#### Scenario: App remains responsive during transcription
- **WHEN** transcription is in progress
- **THEN** the user can start new recordings and interact with the menu bar without interruption

### Requirement: Transcription progress indication
The system SHALL indicate transcription progress in the menu bar.

#### Scenario: Progress shown during transcription
- **WHEN** transcription is running
- **THEN** the menu bar icon shows a progress indicator (spinner or percentage)

#### Scenario: Completion notification
- **WHEN** transcription completes
- **THEN** the system sends a macOS notification with the transcript title

### Requirement: Transcript output as markdown
The system SHALL write the completed transcript as a markdown file in the vault's transcriptions folder with frontmatter metadata and a wikilink to the source recording.

#### Scenario: Transcript file created
- **WHEN** transcription completes for a recording named `2026-04-02-083000.mp4`
- **THEN** the system creates `<vault>/ember/transcriptions/2026-04-02-083000.md` containing YAML frontmatter (title, date, duration, recording wikilink, tags) followed by the transcribed text with timestamp segments

### Requirement: Whisper model selection
The system SHALL allow the user to select which whisper model to use for transcription.

#### Scenario: Default model
- **WHEN** the app is launched for the first time
- **THEN** the bundled `ggml-base.en` model is used for transcription

#### Scenario: User changes model
- **WHEN** the user selects a different model in preferences
- **THEN** subsequent transcriptions use the selected model

### Requirement: Parallel processing for long recordings
The system SHALL use whisper.cpp's parallel processing capability to split long audio across CPU cores.

#### Scenario: Long recording transcription
- **WHEN** a recording longer than 10 minutes is transcribed
- **THEN** the system uses `whisper_full_parallel` to distribute processing across available cores
