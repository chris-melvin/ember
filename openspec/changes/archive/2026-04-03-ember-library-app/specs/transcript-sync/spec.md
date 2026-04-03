## ADDED Requirements

### Requirement: Highlight active transcript segment during playback
The system SHALL visually highlight the transcript segment corresponding to the current playback position.

#### Scenario: Segment highlighted during playback
- **WHEN** the player is at timestamp 0:42 and the transcript has segments at [00:30] and [00:50]
- **THEN** the segment starting at [00:30] is visually highlighted as the active segment

#### Scenario: Auto-scroll to active segment
- **WHEN** the active segment changes during playback and is not visible in the transcript view
- **THEN** the transcript view auto-scrolls to show the active segment

### Requirement: Click timestamp to seek
The system SHALL allow the user to click a transcript timestamp to seek the player to that position.

#### Scenario: Seek via timestamp click
- **WHEN** the user clicks the `[01:20]` timestamp in the transcript
- **THEN** the player seeks to 1 minute 20 seconds and begins or continues playback

### Requirement: Parse transcript timestamps
The system SHALL parse `[MM:SS]` and `[HH:MM:SS]` timestamps from transcript lines to enable sync.

#### Scenario: Standard timestamp format
- **WHEN** a transcript line begins with `[02:30]`
- **THEN** the system associates that segment with the timestamp 2 minutes 30 seconds

#### Scenario: Hour-length timestamp format
- **WHEN** a transcript line begins with `[01:15:00]`
- **THEN** the system associates that segment with the timestamp 1 hour 15 minutes
