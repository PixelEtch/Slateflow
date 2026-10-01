# Changelog

All notable changes to Slateflow are listed here.

## Unreleased

### Added
- `--selftest` launch option for Debug builds, and a GitHub Actions CI workflow that builds the app and runs it.
- README and this changelog.
- `Tools/make-dmg.sh`: builds a Release app and packages it as a drag-to-Applications DMG in `dist/`.
- DMG window background with an arrow and an install hint.
- Privacy manifest (`PrivacyInfo.xcprivacy`) declaring no tracking or data collection, and why the app uses UserDefaults and file metadata.
- `CONTRIBUTING.md`, `SECURITY.md`, issue templates and a pull request template.

### Changed
- The Build Archives / Folder Preview switch and the archive actions sit in the window toolbar (Liquid Glass on macOS 26), with a gap between them; the actions have hover labels. They hide with the inspector.
- Clear Archive (red) and Backup are separate toolbar buttons, always shown, so switching tabs never flashes them in.
- Switching between Build Archives and Folder Preview cross-fades and keeps each pane's scroll position.
- "Saved locally…" stays pinned to the bottom of Build Archives.
- The form keeps a 440 pt minimum width, so controls and the Build button no longer clip when the window shrinks.
- The form now runs Project Folder, Format, Footage Sources, then one Final Cut Pro section (Leave files in place + Smart Collections).
- Footage source presets are two columns of checkboxes.
- Smart Collections linked to a footage source say "from Footage Sources" in their summary, instead of a hover-only link icon.
- Minimum macOS is now 15 (was 14.6, which was never tested).
- The DMG app runs on both Apple silicon and Intel Macs.
- The build number is the commit count, so each release is higher than the last.
- Copyright and app category (Video) are set, so they show in About and Finder's Get Info.
- The About window's GitHub link points to github.com/DXC-Ashifali-Shaikh/Slateflow.

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
