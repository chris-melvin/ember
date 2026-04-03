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
The system SHALL allow the user to stop an active recording via the global hotkey, the floating panel stop button, or the main window stop button, then show the title prompt.

#### Scenario: Stop via global hotkey
- **WHEN** the user presses the global hotkey during an active recording
- **THEN** the recording stops and the title prompt appears

#### Scenario: Stop via preview panel button
- **WHEN** the user clicks the stop button on the floating preview panel
- **THEN** the recording stops and the title prompt appears

#### Scenario: Stop via main window
- **WHEN** the user clicks the stop button in the main window bottom bar
- **THEN** the recording stops and the title prompt appears

### Requirement: Recording output to co-located folder
The system SHALL save recordings to a new co-located folder in the ember directory.

#### Scenario: Video recording saved
- **WHEN** a video+audio recording is stopped and titled
- **THEN** the system creates a folder `ember/<timestamp>-<slug>/` and saves the recording as `recording.mov` inside it

#### Scenario: Audio recording saved
- **WHEN** an audio-only recording is stopped and titled
- **THEN** the system creates a folder `ember/<timestamp>-<slug>/` and saves the recording as `recording.m4a` inside it

### Requirement: New recording appears in library
The system SHALL immediately show new recordings in the library after recording completes.

#### Scenario: Library updates after recording
- **WHEN** a recording is saved and the main window is open
- **THEN** the new recording appears at the top of the recording list
