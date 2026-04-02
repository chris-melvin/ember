## ADDED Requirements

### Requirement: Library window
The system SHALL provide a library window accessible from the menu bar dropdown to browse past recordings.

#### Scenario: Open library
- **WHEN** the user clicks "Library" in the menu bar dropdown
- **THEN** a window opens showing a list of all recordings in the output folder

#### Scenario: Library contents
- **WHEN** the library window is displayed
- **THEN** each entry shows: title (or filename), date, duration, recording type (video/audio), and transcription status (transcribed/pending/none)

### Requirement: Library search
The system SHALL allow searching recordings by title in the library window.

#### Scenario: Search by title
- **WHEN** the user types in the library search field
- **THEN** the list filters to show only recordings whose title or filename contains the search text

### Requirement: Library actions
The system SHALL allow the user to open and delete recordings from the library.

#### Scenario: Open recording in Finder
- **WHEN** the user double-clicks a recording in the library
- **THEN** the system reveals the recording file in Finder

#### Scenario: Delete recording
- **WHEN** the user selects a recording and presses delete
- **THEN** the system shows a confirmation dialog and, if confirmed, deletes the recording file and its associated transcript

### Requirement: Library data source
The system SHALL populate the library by scanning the output folder filesystem, not a separate database.

#### Scenario: Filesystem scan
- **WHEN** the library window opens
- **THEN** the system scans `ember/recordings/` for media files and `ember/transcriptions/` for matching transcript files, parsing frontmatter for metadata
