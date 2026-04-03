# Co-located Storage

## Purpose

Defines the per-recording folder structure where each recording's media, transcript, and metadata are stored together in a self-contained folder.

## Requirements

### Requirement: Per-recording folder structure
The system SHALL store each recording as a self-contained folder named with the recording's timestamp and optional title slug.

#### Scenario: Folder created for new recording
- **WHEN** a new recording is created at 2024-01-15 14:30:22 with title "Standup Notes"
- **THEN** the system creates the folder `ember/2024-01-15-143022-standup-notes/`

#### Scenario: Folder created without title
- **WHEN** a new recording is created at 2024-01-15 14:30:22 and the user skips the title
- **THEN** the system creates the folder `ember/2024-01-15-143022/`

### Requirement: Recording file uses generic name
The system SHALL save the media file inside the recording folder as `recording.<ext>` where ext matches the recording format.

#### Scenario: Video recording file
- **WHEN** a video+audio recording is saved
- **THEN** the media file is saved as `recording.mov` inside the recording folder

#### Scenario: Audio-only recording file
- **WHEN** an audio-only recording is saved
- **THEN** the media file is saved as `recording.m4a` inside the recording folder

### Requirement: Transcript file uses generic name
The system SHALL save the transcript inside the recording folder as `transcript.md`.

#### Scenario: Transcript created after transcription
- **WHEN** transcription completes for a recording
- **THEN** the transcript is saved as `transcript.md` inside the recording's folder

### Requirement: Metadata file per recording
The system SHALL create a `metadata.json` file in each recording folder containing recording metadata.

#### Scenario: Metadata file contents
- **WHEN** a recording folder is created
- **THEN** `metadata.json` contains: `title` (string), `createdAt` (ISO 8601), `duration` (number in seconds), `type` ("video" or "audio"), `tags` (string array), `transcriptionStatus` ("completed", "pending", or "none"), and `editedAt` (ISO 8601 or null)

#### Scenario: Metadata updated on transcription completion
- **WHEN** transcription completes for a recording
- **THEN** `metadata.json` `transcriptionStatus` is set to "completed" and `duration` is populated from the media file

### Requirement: Recording folder as identity
The system SHALL use the folder name as the unique identifier for each recording.

#### Scenario: Folder name uniqueness
- **WHEN** two recordings are created in the same second
- **THEN** the system appends a numeric suffix to ensure unique folder names (e.g., `2024-01-15-143022-2/`)
