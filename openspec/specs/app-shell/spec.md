## MODIFIED Requirements

### Requirement: Menu bar dropdown
The system SHALL show a dropdown menu when the menu bar icon is clicked, including recording mode, library access, and standard actions.

#### Scenario: Dropdown contents
- **WHEN** the user clicks the menu bar icon
- **THEN** a dropdown appears with: recording mode selector (Video + Audio / Audio Only), start/stop recording action, library, transcription queue status (if any), preferences, and quit

### Requirement: Preferences
The system SHALL provide a preferences window with expanded configuration options.

#### Scenario: Configurable settings
- **WHEN** the user opens preferences
- **THEN** they can configure: output folder path, global hotkey combination, whisper model selection, transcript format (Markdown/Plain text/SRT), Obsidian compatibility toggle, and launch at login
