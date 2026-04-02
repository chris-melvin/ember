## ADDED Requirements

### Requirement: Output folder configuration
The system SHALL allow the user to configure an output folder path (replacing "vault path") for storing recordings and transcripts.

#### Scenario: First launch setup
- **WHEN** the app is launched for the first time
- **THEN** the system prompts the user to select an output folder

#### Scenario: Migrate from vault path
- **WHEN** the app launches with an existing `vaultPath` preference but no `outputFolderPath`
- **THEN** the system migrates the value to `outputFolderPath` automatically

### Requirement: Transcript format selection
The system SHALL allow the user to choose the transcript output format from preferences.

#### Scenario: Markdown format (default)
- **WHEN** the user selects "Markdown" format
- **THEN** transcripts are written as `.md` files with YAML frontmatter and timestamped segments

#### Scenario: Plain text format
- **WHEN** the user selects "Plain text" format
- **THEN** transcripts are written as `.txt` files containing only the transcribed text without frontmatter or timestamps

#### Scenario: SRT subtitle format
- **WHEN** the user selects "SRT" format
- **THEN** transcripts are written as `.srt` files with sequential numbering, timestamp ranges (HH:MM:SS,mmm --> HH:MM:SS,mmm), and segment text

### Requirement: Obsidian compatibility toggle
The system SHALL provide a toggle for Obsidian-compatible output (wikilinks in frontmatter).

#### Scenario: Obsidian mode enabled (default)
- **WHEN** Obsidian compatibility is enabled
- **THEN** the frontmatter `recording` field uses Obsidian wikilink syntax: `"[[ember/recordings/filename.mov]]"`

#### Scenario: Obsidian mode disabled
- **WHEN** Obsidian compatibility is disabled
- **THEN** the frontmatter `recording` field uses a relative file path: `"../recordings/filename.mov"`
