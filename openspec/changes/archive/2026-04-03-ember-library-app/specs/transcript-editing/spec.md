## ADDED Requirements

### Requirement: Inline transcript editing
The system SHALL allow the user to edit transcript text directly in the detail view.

#### Scenario: Edit transcript text
- **WHEN** the user clicks on a transcript segment and modifies the text
- **THEN** the text is editable inline without entering a separate mode

#### Scenario: Preserve timestamp format
- **WHEN** the user edits transcript text
- **THEN** the `[MM:SS]` timestamp prefixes are preserved and not editable

### Requirement: Auto-save edited transcripts
The system SHALL automatically save transcript edits to disk with debouncing.

#### Scenario: Debounced auto-save
- **WHEN** the user stops typing for 500 milliseconds
- **THEN** the system writes the updated transcript to `transcript.md`

#### Scenario: Metadata updated on edit
- **WHEN** a transcript is saved after editing
- **THEN** the `metadata.json` `editedAt` field is updated to the current timestamp

### Requirement: Undo transcript edits
The system SHALL support undo/redo for transcript edits within the current session.

#### Scenario: Undo edit
- **WHEN** the user presses Cmd+Z after editing a transcript
- **THEN** the last edit is undone
