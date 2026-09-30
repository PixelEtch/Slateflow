# Changelog

All notable changes to Slateflow are listed here.

## Unreleased

### Added
- `--selftest` launch option for Debug builds, and a GitHub Actions CI workflow that builds the app and runs it.
- README and this changelog.

## 2026-09-30

### Added
- Footage source presets: Insta360, DJI Osmo, Sony, iPhone and Webcam. Typing a preset's name turns on the preset instead of adding a duplicate.
- A window after each build with numbered steps for Final Cut's library dialog. Its main button copies the project name and opens the project.
- Visible remove buttons for Smart Collections you added yourself.

### Changed
- Text fields now have borders, so they're visible without hovering.
- The "Leave files in place" explanation is shown under the option instead of only as a tooltip.
- Before a destination is picked, the project name shows `NNN - Name`. The real number is set when you build.
- Final Cut now creates the project library itself, in the project's `FCP` folder.
- Long dashes in labels and messages are now plain hyphens.

### Removed
- The bundled blank Final Cut library. It was saved by an older Final Cut Pro, so every project asked to update. It also stored folder locations from the developer's Mac, which created stray backup and cache folders.
- Swipe-to-remove gestures, which had no effect on macOS.

### Fixed
- The project number no longer shows a stale value (for example `001` when `002` already exists).
- Build history rows can be expanded with VoiceOver and the keyboard.

## 2026-09-17

### Changed
- Split the code into model and view layers, and cleaned up the project.

## 2026-08-28

- First version.
