# Full-text Search

## Purpose

Enables searching recordings by matching against titles and transcript content across the entire library.

## Requirements

### Requirement: Search across titles and transcript content
The system SHALL allow the user to search recordings by matching against titles and transcript text.

#### Scenario: Search matches title
- **WHEN** the user types "standup" in the search field
- **THEN** recordings with "standup" in the title appear in results

#### Scenario: Search matches transcript content
- **WHEN** the user types "caching strategy" in the search field
- **THEN** recordings whose transcript contains "caching strategy" appear in results

#### Scenario: Case-insensitive search
- **WHEN** the user types "API" in the search field
- **THEN** recordings matching "api", "Api", or "API" in title or transcript all appear

### Requirement: Search results in sidebar
The system SHALL display search results in the recording list, replacing the normal sorted list.

#### Scenario: Search results replace list
- **WHEN** the user has an active search query
- **THEN** the recording list shows only matching recordings

#### Scenario: Clear search restores full list
- **WHEN** the user clears the search field
- **THEN** the recording list returns to showing all recordings with the current filter applied

### Requirement: Search field in sidebar
The system SHALL provide a persistent search field in the sidebar.

#### Scenario: Search field location
- **WHEN** the main window is displayed
- **THEN** a search field is visible in the sidebar area
