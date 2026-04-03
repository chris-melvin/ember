# Storage Migration

## Purpose

Handles one-time migration of recordings from the old split-folder storage format (separate `recordings/` and `transcriptions/` directories) to the new co-located folder structure.

## Requirements

### Requirement: Detect old storage format
The system SHALL detect the presence of the old split-folder storage format on launch.

#### Scenario: Old format detected
- **WHEN** the app launches and `ember/recordings/` contains media files directly (not inside subfolders)
- **THEN** the system identifies that migration is needed

#### Scenario: Already migrated
- **WHEN** the app launches and `ember/recordings/` does not exist or is empty
- **THEN** the system skips migration

### Requirement: Migrate recordings to co-located folders
The system SHALL migrate each recording from the old format to a co-located folder.

#### Scenario: Recording with matching transcript
- **WHEN** migration processes `ember/recordings/2024-01-15-143022-standup.mov` and finds `ember/transcriptions/2024-01-15-143022-standup.md`
- **THEN** the system creates `ember/2024-01-15-143022-standup/`, moves the recording as `recording.mov`, strips YAML frontmatter from the transcript and saves as `transcript.md`, and generates `metadata.json` from the frontmatter fields

#### Scenario: Recording without transcript
- **WHEN** migration processes a recording that has no matching transcript file
- **THEN** the system creates the co-located folder with the recording file and a `metadata.json` with `transcriptionStatus` set to "none"

#### Scenario: Frontmatter fields mapped to metadata.json
- **WHEN** a transcript with YAML frontmatter containing `title`, `date`, `duration`, and `tags` is migrated
- **THEN** the system maps these fields to the corresponding `metadata.json` fields

### Requirement: Migration user notification
The system SHALL inform the user before and after migration.

#### Scenario: Pre-migration dialog
- **WHEN** migration is needed on launch
- **THEN** the system shows a dialog explaining that recordings will be reorganized and asking the user to proceed

#### Scenario: Post-migration summary
- **WHEN** migration completes
- **THEN** the system shows the number of recordings migrated and any files that failed to migrate

### Requirement: Migration fault tolerance
The system SHALL handle individual file failures without aborting the entire migration.

#### Scenario: Single file migration failure
- **WHEN** one recording file cannot be moved (e.g., permissions error)
- **THEN** the system logs the failure, skips that file, and continues migrating remaining recordings

#### Scenario: Original files preserved on failure
- **WHEN** a recording fails to migrate
- **THEN** the original files in the old location remain untouched

### Requirement: Clean up old directories after migration
The system SHALL remove the old empty directories after successful migration.

#### Scenario: Old directories removed
- **WHEN** all recordings have been successfully migrated from `ember/recordings/` and `ember/transcriptions/`
- **THEN** the system removes these now-empty directories

#### Scenario: Old directories retained if files remain
- **WHEN** some recordings failed to migrate
- **THEN** the old directories are kept with the remaining files
