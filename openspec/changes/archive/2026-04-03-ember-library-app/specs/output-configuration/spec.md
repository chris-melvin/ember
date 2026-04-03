## MODIFIED Requirements

### Requirement: Output folder configuration
The system SHALL allow the user to configure an output folder path for storing recordings.

#### Scenario: First launch setup
- **WHEN** the app is launched for the first time
- **THEN** the system prompts the user to select an output folder

#### Scenario: Migrate from vault path
- **WHEN** the app launches with an existing `vaultPath` preference but no `outputFolderPath`
- **THEN** the system migrates the value to `outputFolderPath` automatically

## REMOVED Requirements

### Requirement: Transcript format selection
**Reason**: Transcripts are now standardized as clean timestamped markdown. SRT and plain text formats are no longer supported.
**Migration**: Existing SRT and plain text transcripts will be preserved as-is during storage migration but new transcripts will always be markdown.

### Requirement: Obsidian compatibility toggle
**Reason**: Obsidian integration has been dropped. Transcripts no longer use YAML frontmatter or wikilinks. Metadata is stored in `metadata.json`.
**Migration**: Existing frontmatter data is migrated to `metadata.json` during storage migration. Transcript files are stripped of frontmatter.
