## ADDED Requirements

### Requirement: Configurable vault path
The system SHALL allow the user to configure the path to their Obsidian vault.

#### Scenario: First launch vault setup
- **WHEN** the app is launched for the first time without a configured vault path
- **THEN** the system prompts the user to select their Obsidian vault directory

#### Scenario: Change vault path
- **WHEN** the user changes the vault path in preferences
- **THEN** subsequent recordings and transcripts are saved to the new vault location

### Requirement: Vault folder structure
The system SHALL create and maintain an `ember/` folder structure within the configured vault.

#### Scenario: Folder creation on first recording
- **WHEN** the first recording is made and `ember/recordings/` and `ember/transcriptions/` do not exist in the vault
- **THEN** the system creates both directories

#### Scenario: Existing folders preserved
- **WHEN** the ember folders already exist with prior content
- **THEN** new files are added without modifying existing files

### Requirement: Transcript markdown format
The system SHALL write transcript files with YAML frontmatter containing metadata and a wikilink to the source recording.

#### Scenario: Frontmatter structure
- **WHEN** a transcript file is created
- **THEN** it contains YAML frontmatter with: `title`, `date` (ISO 8601), `duration` (mm:ss), `recording` (Obsidian wikilink to .mp4), and `tags` (including `ember/transcript`)

#### Scenario: Wikilink to recording
- **WHEN** a transcript is created for `ember/recordings/2026-04-02-083000.mp4`
- **THEN** the frontmatter `recording` field contains `"[[ember/recordings/2026-04-02-083000.mp4]]"`

### Requirement: File naming convention
The system SHALL use timestamp-based naming for all generated files.

#### Scenario: Consistent naming
- **WHEN** a recording is made at 2026-04-02 08:30:00
- **THEN** the recording is named `2026-04-02-083000.mp4` and the transcript is named `2026-04-02-083000.md`
