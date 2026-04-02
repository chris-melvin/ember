## Why

Ember v1 is tightly coupled to Obsidian (wikilinks, vault terminology) and only supports video recording with timestamp-based naming. To make Ember useful to a broader audience and more practical for everyday use, we need configurable output, a recording library, audio-only mode, and the ability to title recordings after capture.

## What Changes

- **Generalize beyond Obsidian**: Rename "vault" to "output folder" in UI, but keep Obsidian compatibility (frontmatter, wikilinks) as the default format
- **Configurable output format**: Support plain markdown (with frontmatter), plain text, and SRT subtitle formats for transcripts
- **Recording library view**: Browse, search, and manage past recordings within Ember — don't require an external tool to find old captures
- **Audio-only mode**: Option to record audio without video for lighter captures (voice notes, phone calls, etc.)
- **Title prompt after recording**: When recording stops, prompt the user for a title instead of using only timestamps — title becomes the filename and frontmatter title field

## Capabilities

### New Capabilities
- `output-configuration`: Configurable output folder, format selection (markdown/text/SRT), and Obsidian compatibility toggle for wikilinks
- `recording-library`: In-app library view to browse, search, play, and delete past recordings and their transcripts
- `audio-only-mode`: Audio-only recording option that skips camera capture and outputs smaller files
- `title-prompt`: Post-recording title prompt that names the output files and populates frontmatter

### Modified Capabilities
- `vault-integration`: Generalize from "vault" to "output folder"; make wikilinks optional; keep frontmatter as default
- `recording-capture`: Add audio-only mode toggle; integrate title prompt into stop-recording flow
- `app-shell`: Add library view access from menu bar; add audio/video mode toggle

## Impact

- **UI**: New library window, title prompt sheet/popover, preferences additions for output format
- **File naming**: Changes from pure timestamp to `YYYY-MM-DD-HHmmss-user-title.mov/.md` when title is provided
- **Recording pipeline**: Audio-only path skips AVCaptureDevice video input and outputs .m4a instead of .mov
- **Existing recordings**: Fully backward compatible — old timestamp-named files remain valid
