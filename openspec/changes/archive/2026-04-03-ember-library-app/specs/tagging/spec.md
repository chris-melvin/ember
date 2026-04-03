## ADDED Requirements

### Requirement: Add tags to recordings
The system SHALL allow the user to add tags to a recording from the detail view.

#### Scenario: Add a tag
- **WHEN** the user types a tag name and confirms in the detail view tag editor
- **THEN** the tag is added to the recording's `metadata.json` `tags` array and the sidebar tag list updates

#### Scenario: Tag created by typing
- **WHEN** the user types a tag that does not exist on any recording
- **THEN** the tag is created and added to the recording

### Requirement: Remove tags from recordings
The system SHALL allow the user to remove tags from a recording.

#### Scenario: Remove a tag
- **WHEN** the user removes a tag from a recording in the detail view
- **THEN** the tag is removed from the recording's `metadata.json` `tags` array

#### Scenario: Tag disappears when unused
- **WHEN** the last recording with a given tag has that tag removed
- **THEN** the tag no longer appears in the sidebar tag list

### Requirement: Filter recordings by tag
The system SHALL allow the user to filter the recording list by selecting a tag in the sidebar.

#### Scenario: Filter by tag
- **WHEN** the user clicks a tag in the sidebar
- **THEN** the recording list shows only recordings with that tag

#### Scenario: Clear tag filter
- **WHEN** the user clicks "All Recordings" in the sidebar
- **THEN** the tag filter is cleared and all recordings are shown

### Requirement: Sidebar tag list with counts
The system SHALL display all unique tags in the sidebar with recording counts.

#### Scenario: Tag list display
- **WHEN** the sidebar is displayed
- **THEN** a "Tags" section shows each unique tag with the number of recordings that have it
