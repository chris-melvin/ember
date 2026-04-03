## MODIFIED Requirements

### Requirement: Output folder configuration
The system SHALL allow the user to configure an output folder path for storing recordings.

#### Scenario: First launch setup
- **WHEN** the app is launched for the first time
- **THEN** the system prompts the user to select an output folder

#### Scenario: Migrate from vault path
- **WHEN** the app launches with an existing `vaultPath` preference but no `outputFolderPath`
- **THEN** the system migrates the value to `outputFolderPath` automatically
