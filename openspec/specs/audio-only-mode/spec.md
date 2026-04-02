## ADDED Requirements

### Requirement: Audio-only recording toggle
The system SHALL allow the user to switch between video+audio and audio-only recording modes from the menu bar.

#### Scenario: Select audio-only mode
- **WHEN** the user selects "Record Audio Only" from the menu bar dropdown
- **THEN** subsequent recordings capture only microphone audio without camera video

#### Scenario: Select video+audio mode
- **WHEN** the user selects "Record Video + Audio" from the menu bar dropdown
- **THEN** subsequent recordings capture both camera video and microphone audio

### Requirement: Audio-only recording output
The system SHALL save audio-only recordings as `.m4a` files.

#### Scenario: Audio-only file saved
- **WHEN** an audio-only recording is stopped
- **THEN** the system saves an `.m4a` file to the output folder's `ember/recordings/` directory

#### Scenario: Audio-only transcript references correct file
- **WHEN** an audio-only recording is transcribed
- **THEN** the transcript's recording reference points to the `.m4a` file

### Requirement: Audio-only floating panel
The system SHALL display a minimal floating panel during audio-only recording without camera preview.

#### Scenario: Audio-only panel appearance
- **WHEN** an audio-only recording is active
- **THEN** the floating panel shows an audio indicator, elapsed timer, and stop button — no camera preview

### Requirement: Audio-only does not require camera permission
The system SHALL NOT request camera permission for audio-only recordings.

#### Scenario: Camera permission not needed
- **WHEN** the user records in audio-only mode and has not granted camera permission
- **THEN** the recording proceeds using only microphone access
