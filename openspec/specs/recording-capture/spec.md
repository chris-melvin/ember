## MODIFIED Requirements

### Requirement: Start recording via global hotkey
The system SHALL register a configurable global hotkey that starts a new recording (video+audio or audio-only based on current mode) from any application context.

#### Scenario: User triggers video recording
- **WHEN** the user presses the configured global hotkey while in video+audio mode
- **THEN** the system begins capturing video and audio and displays the floating preview panel with camera feed

#### Scenario: User triggers audio-only recording
- **WHEN** the user presses the configured global hotkey while in audio-only mode
- **THEN** the system begins capturing audio only and displays the floating panel with audio indicator

#### Scenario: Hotkey pressed while already recording
- **WHEN** the user presses the global hotkey while a recording is already in progress
- **THEN** the system stops the current recording and shows the title prompt

### Requirement: Stop recording
The system SHALL allow the user to stop an active recording via the global hotkey or the stop button, then show the title prompt.

#### Scenario: Stop via global hotkey
- **WHEN** the user presses the global hotkey during an active recording
- **THEN** the recording stops and the title prompt appears on the floating panel

#### Scenario: Stop via preview panel button
- **WHEN** the user clicks the stop button on the floating preview panel
- **THEN** the recording stops and the title prompt appears on the floating panel

### Requirement: Video+audio capture output
The system SHALL capture video and audio using AVFoundation and save the output as a `.mov` file.

#### Scenario: Video recording saved
- **WHEN** a video+audio recording is stopped and titled
- **THEN** the system saves a `.mov` file to the output folder's `ember/recordings/` directory

#### Scenario: Long recording support
- **WHEN** a recording runs for over 1 hour
- **THEN** the system continues recording without interruption or data loss
