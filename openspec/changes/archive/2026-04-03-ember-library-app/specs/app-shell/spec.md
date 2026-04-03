## ADDED Requirements

### Requirement: Main application window
The system SHALL provide a main window as the primary interface for browsing and managing recordings.

#### Scenario: Main window layout
- **WHEN** the main window is opened
- **THEN** it displays a three-column NavigationSplitView with sidebar (filters/tags), recording list, and detail view

#### Scenario: Open main window from menu bar
- **WHEN** the user clicks "Library" in the menu bar dropdown or presses Cmd+L
- **THEN** the main window opens and comes to front

#### Scenario: Main window minimum size
- **WHEN** the main window is displayed
- **THEN** it has a minimum size of 800x500 points and is resizable

### Requirement: Bottom status bar
The system SHALL display a status bar at the bottom of the main window showing recording state and controls.

#### Scenario: Idle state
- **WHEN** no recording is in progress
- **THEN** the bottom bar shows "Ready to record", the current recording mode, and the hotkey hint

#### Scenario: Recording state
- **WHEN** a recording is in progress
- **THEN** the bottom bar shows a red recording indicator, elapsed time, and a stop button

#### Scenario: Transcribing state
- **WHEN** transcription is in progress
- **THEN** the bottom bar shows a transcribing indicator with the recording name

## MODIFIED Requirements

### Requirement: Menu bar dropdown
The system SHALL show a dropdown menu when the menu bar icon is clicked, including recording mode, library access, and standard actions.

#### Scenario: Dropdown contents
- **WHEN** the user clicks the menu bar icon
- **THEN** a dropdown appears with: recording mode selector (Video + Audio / Audio Only), start/stop recording action, library (opens main window), preferences, and quit

### Requirement: Preferences
The system SHALL provide a preferences window with configuration options.

#### Scenario: Configurable settings
- **WHEN** the user opens preferences
- **THEN** they can configure: output folder path, global hotkey combination, whisper model selection, and launch at login
