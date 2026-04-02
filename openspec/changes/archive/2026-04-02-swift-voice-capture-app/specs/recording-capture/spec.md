## ADDED Requirements

### Requirement: Start recording via global hotkey
The system SHALL register a configurable global hotkey that starts a new video+audio recording from any application context.

#### Scenario: User triggers recording from another app
- **WHEN** the user presses the configured global hotkey (default: Cmd+Shift+R) while any application is focused
- **THEN** the system begins capturing video from the default camera and audio from the default microphone, and displays the floating preview panel

#### Scenario: Hotkey pressed while already recording
- **WHEN** the user presses the global hotkey while a recording is already in progress
- **THEN** the system stops the current recording and begins saving

### Requirement: Stop recording
The system SHALL allow the user to stop an active recording via the global hotkey or the stop button on the floating preview panel.

#### Scenario: Stop via global hotkey
- **WHEN** the user presses the global hotkey during an active recording
- **THEN** the recording stops and the .mp4 file is saved to the vault recordings folder

#### Scenario: Stop via preview panel button
- **WHEN** the user clicks the stop button on the floating preview panel
- **THEN** the recording stops and the .mp4 file is saved to the vault recordings folder

### Requirement: Floating video preview during recording
The system SHALL display a small floating panel showing the live camera feed, a recording timer, and a stop button while recording is active.

#### Scenario: Preview panel appears on recording start
- **WHEN** a recording begins
- **THEN** a floating panel appears showing the camera preview, an elapsed time counter, and a stop button

#### Scenario: Preview panel does not steal focus
- **WHEN** the floating preview panel is visible
- **THEN** the previously focused application remains focused and the panel floats above all windows without activating

#### Scenario: Preview panel dismissed on recording stop
- **WHEN** a recording is stopped
- **THEN** the floating preview panel is dismissed

### Requirement: Video+audio capture output
The system SHALL capture video and audio using AVFoundation and save the output as a single .mp4 file.

#### Scenario: Recording saved to vault
- **WHEN** a recording is stopped
- **THEN** the system saves a .mp4 file to `<vault>/ember/recordings/` with the naming convention `YYYY-MM-DD-HHmmss.mp4`

#### Scenario: Long recording support
- **WHEN** a recording runs for over 1 hour
- **THEN** the system continues recording without interruption or data loss
