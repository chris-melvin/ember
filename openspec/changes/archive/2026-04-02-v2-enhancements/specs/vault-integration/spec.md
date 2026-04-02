## MODIFIED Requirements

### Requirement: Configurable vault path
The system SHALL allow the user to configure the path to their output folder.

#### Scenario: First launch setup
- **WHEN** the app is launched for the first time without a configured output folder path
- **THEN** the system prompts the user to select their output folder directory

#### Scenario: Change output folder path
- **WHEN** the user changes the output folder path in preferences
- **THEN** subsequent recordings and transcripts are saved to the new location

### Requirement: Transcript markdown format
The system SHALL write transcript files with YAML frontmatter containing metadata and a link to the source recording, with optional Obsidian wikilink syntax.

#### Scenario: Frontmatter structure
- **WHEN** a transcript markdown file is created
- **THEN** it contains YAML frontmatter with: `title`, `date` (ISO 8601), `duration` (mm:ss), `recording` (link to recording file), and `tags` (including `ember/transcript`)

#### Scenario: Obsidian wikilink enabled
- **WHEN** Obsidian compatibility is enabled in preferences
- **THEN** the frontmatter `recording` field uses wikilink syntax: `"[[ember/recordings/filename.mov]]"`

#### Scenario: Obsidian wikilink disabled
- **WHEN** Obsidian compatibility is disabled in preferences
- **THEN** the frontmatter `recording` field uses a relative path: `"../recordings/filename.mov"`

### Requirement: File naming convention
The system SHALL use timestamp-based naming with optional title slug for all generated files.

#### Scenario: Naming with title
- **WHEN** a recording is made at 2026-04-02 08:30:00 and the user provides the title "Morning Thoughts"
- **THEN** the recording is named `2026-04-02-083000-morning-thoughts.mov` and the transcript is named `2026-04-02-083000-morning-thoughts.md`

#### Scenario: Naming without title
- **WHEN** a recording is made at 2026-04-02 08:30:00 and the user skips the title prompt
- **THEN** the recording is named `2026-04-02-083000.mov` and the transcript is named `2026-04-02-083000.md`
