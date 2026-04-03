## ADDED Requirements

### Requirement: In-app audio playback
The system SHALL provide audio playback within the detail view for audio recordings.

#### Scenario: Play audio recording
- **WHEN** the user selects an audio recording and presses the play button
- **THEN** the system plays the audio using AVPlayer with a seek bar showing elapsed and total time

#### Scenario: Pause audio
- **WHEN** the user presses the pause button during audio playback
- **THEN** playback pauses and the seek bar position is preserved

### Requirement: In-app video playback
The system SHALL provide video playback within the detail view for video recordings.

#### Scenario: Play video recording
- **WHEN** the user selects a video recording and presses the play button
- **THEN** the system plays the video inline in the detail view with transport controls

### Requirement: Seek bar
The system SHALL display a seek bar with transport controls for all recordings.

#### Scenario: Scrub to position
- **WHEN** the user drags the seek bar to a new position
- **THEN** playback jumps to that position and the current time display updates

#### Scenario: Time display
- **WHEN** a recording is loaded in the detail view
- **THEN** the seek bar shows elapsed time and total duration in `M:SS` or `H:MM:SS` format

### Requirement: Playback state persistence within session
The system SHALL preserve playback position when switching between recordings.

#### Scenario: Return to previously played recording
- **WHEN** the user switches away from a recording and then switches back within the same app session
- **THEN** the seek bar returns to the last playback position for that recording
