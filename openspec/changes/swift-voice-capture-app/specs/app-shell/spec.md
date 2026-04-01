## ADDED Requirements

### Requirement: Menu bar presence
The system SHALL run as a macOS menu bar app with a status item icon.

#### Scenario: App appears in menu bar
- **WHEN** the app is launched
- **THEN** an icon appears in the macOS menu bar and no Dock icon is shown

#### Scenario: Menu bar icon states
- **WHEN** the app is idle
- **THEN** the menu bar icon shows a default state
- **WHEN** the app is recording
- **THEN** the menu bar icon changes to indicate active recording
- **WHEN** the app is transcribing
- **THEN** the menu bar icon shows a transcription-in-progress indicator

### Requirement: Menu bar dropdown
The system SHALL show a dropdown menu when the menu bar icon is clicked.

#### Scenario: Dropdown contents
- **WHEN** the user clicks the menu bar icon
- **THEN** a dropdown appears with: start/stop recording action, transcription queue status (if any), preferences, and quit

### Requirement: Global hotkey registration
The system SHALL register a global keyboard shortcut that works from any application.

#### Scenario: Hotkey works system-wide
- **WHEN** the user presses the configured hotkey in any application
- **THEN** the recording starts or stops

#### Scenario: Accessibility permission required
- **WHEN** the app launches and Accessibility permission has not been granted
- **THEN** the system shows an onboarding prompt explaining why the permission is needed and links to System Settings

### Requirement: Preferences
The system SHALL provide a preferences window for configuration.

#### Scenario: Configurable settings
- **WHEN** the user opens preferences
- **THEN** they can configure: vault path, global hotkey combination, whisper model selection, and video quality

### Requirement: Launch at login
The system SHALL offer an option to launch at macOS login.

#### Scenario: Enable launch at login
- **WHEN** the user enables "Launch at Login" in preferences
- **THEN** the app starts automatically when macOS boots

### Requirement: Camera and microphone permissions
The system SHALL request camera and microphone access on first use.

#### Scenario: Permission request flow
- **WHEN** the user triggers their first recording
- **THEN** macOS permission dialogs appear for camera and microphone access

#### Scenario: Permission denied handling
- **WHEN** the user denies camera or microphone permission
- **THEN** the system shows an error explaining that recording requires these permissions and how to enable them in System Settings
