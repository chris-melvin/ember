## MODIFIED Requirements

### Requirement: Library window
The system SHALL provide a library as the main window of the application to browse past recordings.

#### Scenario: Open library
- **WHEN** the user clicks "Library" in the menu bar dropdown or presses Cmd+L
- **THEN** the main window opens showing the full library interface

#### Scenario: Library contents
- **WHEN** the library is displayed
- **THEN** the recording list shows each entry with: title (or folder name), date, duration, recording type icon (video/audio), and transcription status badge

### Requirement: Library search
The system SHALL allow searching recordings by title and transcript content in the library.

#### Scenario: Search by title or content
- **WHEN** the user types in the library search field
- **THEN** the list filters to show recordings whose title or transcript text contains the search query (case-insensitive)

### Requirement: Library actions
The system SHALL allow the user to manage recordings from the library.

#### Scenario: Select recording to view details
- **WHEN** the user clicks a recording in the list
- **THEN** the detail view shows the recording's playback controls, transcript, and metadata

#### Scenario: Delete recording
- **WHEN** the user right-clicks a recording and selects "Delete"
- **THEN** the system shows a confirmation dialog and, if confirmed, deletes the entire recording folder

#### Scenario: Reveal in Finder
- **WHEN** the user right-clicks a recording and selects "Reveal in Finder"
- **THEN** the system opens Finder with the recording folder selected

### Requirement: Library data source
The system SHALL populate the library by scanning co-located recording folders from disk.

#### Scenario: Filesystem scan
- **WHEN** the library loads
- **THEN** the system scans the `ember/` directory for recording folders, reads each `metadata.json` for metadata, and loads transcript content for search indexing

### Requirement: Sidebar date grouping
The system SHALL group recordings by time period in the sidebar.

#### Scenario: Date groups displayed
- **WHEN** the sidebar is displayed
- **THEN** it shows time-based filters: "All Recordings", "Today", "This Week", "This Month" with recording counts

#### Scenario: Filter by date group
- **WHEN** the user clicks "This Week" in the sidebar
- **THEN** the recording list shows only recordings created within the current week

### Requirement: Recording list sorting
The system SHALL sort recordings by creation date, newest first.

#### Scenario: Default sort order
- **WHEN** the recording list is displayed without filters
- **THEN** recordings are sorted by creation date in descending order (newest first)
