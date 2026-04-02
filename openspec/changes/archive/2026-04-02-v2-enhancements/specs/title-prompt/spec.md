## ADDED Requirements

### Requirement: Title prompt after recording
The system SHALL display a title input prompt when a recording is stopped.

#### Scenario: Title prompt appears
- **WHEN** a recording is stopped
- **THEN** the floating panel transitions to show a text field for entering a title, with "Save" and "Skip" buttons

#### Scenario: User enters a title
- **WHEN** the user types a title and clicks "Save"
- **THEN** the recording and transcript files are named `YYYY-MM-DD-HHmmss-slugified-title` and the frontmatter `title` field is set to the user's input

#### Scenario: User skips title
- **WHEN** the user clicks "Skip"
- **THEN** the recording and transcript files use the timestamp-only naming convention `YYYY-MM-DD-HHmmss`

### Requirement: Title slugification
The system SHALL convert user-provided titles into filesystem-safe slugs for filenames.

#### Scenario: Title with spaces and special characters
- **WHEN** the user enters "My Morning Thoughts! (Day 1)"
- **THEN** the slug becomes `my-morning-thoughts-day-1`

#### Scenario: Very long title
- **WHEN** the user enters a title longer than 60 characters
- **THEN** the slug is truncated to 60 characters at a word boundary

#### Scenario: Empty or whitespace-only title
- **WHEN** the user enters only whitespace and clicks "Save"
- **THEN** the system treats it as a skip and uses timestamp-only naming
