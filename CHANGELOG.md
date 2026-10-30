# Changelog

All notable changes to Slateflow are listed here.

## Unreleased

### Changed
- The main window shows only what changes per project: Project name, Format and Cameras. Folders and the Final Cut options (Leave files in place, Smart Collections) moved to **Slateflow ▸ Customize Projects…** (⌘,), in two tabs: **Folders** and **Smart Collections**.
- A **Folders and Smart Collections** row under Cameras shows how many each project gets, with **Customize…** to change them. The Folder Preview has **Edit Folders…** and **Edit Smart Collections…** links, and a one-time tip points new users to the row.
- "Build" is now **Create Project**: the button, the File menu item and the folder picker's **Create Here**. The first-time button reads **Choose Folder & Create Project…**.
- **Create Project…** uses ⌘N and replaces New Window. ⌘B still works.
- The bottom bar reads as one line: Creates “NNN - Name” in **Folder** · Change….
- The Root folder row and its note are gone; hover over the project name to see how the number is picked.
- Build Archives is now **Recent Projects**, and Footage Sources is now **Cameras**.
- The success window is shorter. The one-time Final Cut settings (Leave files in place, Keywords: From folders, and where to put Backups) are explained under Smart Collections in Customize Projects instead.

## 1.0.0-alpha.5 - 2026-10-30

### Added
- Color space: Standard (Rec. 709), Wide Gamut (Rec. 2020), HDR (Rec. 2020 HLG) or HDR (Rec. 2020 PQ). The timelines use it and the library is set up to match: Standard, Wide Gamut or Wide Gamut HDR. Footage from any camera is converted to it.
- Reel timeline: also adds a 9:16 timeline (for example 2160 × 3840 at 4K) next to the main one, for cutting a reel from the same shoot. Offered for landscape and portrait projects at a preset resolution.

### Fixed
- Open in Final Cut Pro works again after relaunching Slateflow. With a remembered build folder, macOS said Slateflow didn't have permission to open the project's `.fcpxml`, and the success window said Final Cut hadn't created the library. Broken since 1.0.0-alpha.3.

## 1.0.0-alpha.4 - 2026-10-29

### Changed
- New default app icon: light stars and gear on a purple tile. It shows in light mode, Finder and on the mounted DMG; dark mode keeps purple stars on a dark tile.

## 1.0.0-alpha.3 - 2026-10-29

### Added
- Folders: add, remove or nest the project's folders (Admin, Audio, Final Exports, Graphics, Images by default; type `Admin/Contracts` for a subfolder). Restore Defaults brings back the standard set. Backup, FCP and Footage are always created.
- Slateflow remembers where you build. After the first build the button is just **Build**; **Change…** next to the folder name picks another.
- After a build, the success window says to set Backups to the project's `Backup` folder when Final Cut asks for storage locations. Media and render files already stay inside the project; Final Cut has no setting Slateflow can use to choose the backup folder.

### Changed
- Each project's top level shows only folders. The build record is now the hidden `.slateflow.json` (was `Slate Project.json`), and `FCP/Import Settings.md` is no longer written: the app says to turn on Leave files in place when it matters.
- "Template name" is now "Project name".
- The "Project" section is now "Format", so it isn't confused with Project Folder.
- Folders is collapsed to a one-line summary until you open it. Restore Defaults shows only when the folders differ from the defaults.
- The project name is no longer selected when the window opens, so a stray key can't replace it.
- Clicking outside a text field, or pressing Return in Project name, ends editing.
- The bottom bar shortens the destination folder before the project name.
- VoiceOver names the item each remove button removes ("Remove Admin › Scripts").
- The "Leave files in place" switch says to turn on the same setting in Final Cut Pro, which doesn't take it from the project. The success window repeats it.
- Custom width and height must be at least 16 px; smaller values are raised on build. Before, a 2 px-wide project was allowed.

### Fixed
- The mounted DMG shows the Slateflow icon instead of a generic disk icon. 1.0.0-alpha.2 was meant to, but Finder removed the icon while arranging the DMG window.

## 1.0.0-alpha.2 - 2026-10-29

### Added
- Help menu: Slateflow Help (⌘?), Troubleshooting, Release Notes, Privacy and Report an Issue open the matching GitHub pages. Before, Slateflow Help only said help wasn't available.

## 1.0.0-alpha.1 - 2026-10-28

First public test build. A beta follows, then 1.0.0.

### Changed
- Releases are built, signed, notarized and published by GitHub Actions when a version tag is pushed. The update feed is served from the `gh-pages` branch.
- Open in Final Cut Pro now has Final Cut create the project's library in its `FCP` folder and import the project, with nothing to click in Final Cut. The `.fcpxml` names the library with FCPXML's `library location` import option. The button was "Copy Name & Open in Final Cut Pro".

### Fixed
- An unreadable Build Archives file is kept next to the archive as `BuildHistory.unreadable-<date>.json` instead of being overwritten by the next build.
- The Build Archives storage note no longer overlaps the list when it scrolls.
- Project folders and files use your Mac's default permissions. Before, Slateflow always made them readable by every account on the Mac, even if you had set new files to private.

## 2026-10-16

### Added
- `--selftest` launch option for Debug builds, and a GitHub Actions CI workflow that builds the app and runs it.
- README and this changelog.
- `Tools/make-dmg.sh`: builds a Release app and packages it as a drag-to-Applications DMG in `dist/`.
- DMG window background with an arrow and an install hint.
- Privacy manifest (`PrivacyInfo.xcprivacy`) declaring no tracking or data collection, and why the app uses UserDefaults and file metadata.
- `CONTRIBUTING.md`, `SECURITY.md`, issue templates and a pull request template.
- Check for Updates… in the app menu, using Sparkle. Updates come from the PixelEtch GitHub releases and are verified with an EdDSA signature before install.
- `SUPPORT.md`, `docs/PRIVACY.md`, `docs/TROUBLESHOOTING.md`, architecture decision records in `docs/adr/`, `CODEOWNERS` and Dependabot for GitHub Actions.
- README sections for Uninstall and Documentation.
- `CODE_OF_CONDUCT.md`, and merge requirements in `CONTRIBUTING.md`.
- Release pipeline: `Tools/make-dmg.sh` signs with Developer ID, notarizes and staples the DMG, and updates the Sparkle feed in `docs/appcast.xml` for GitHub Pages.

### Changed
- Footage sources (including custom ones), roles and Smart Collections are saved and restored on the next launch.
- The inspector remembers whether it's shown and which tab is selected.
- The Build Archives / Folder Preview switch and the archive actions sit in the window toolbar (Liquid Glass on macOS 26), with a gap between them; the actions have hover labels. They hide with the inspector.
- Clear Archive (red) and Backup share one Xcode-style toolbar tray with a divider, shown only on Build Archives; the tray draws its own glass so switching tabs never flashes empty outlines.
- Smart Collection and "Leave files in place" switches are vertically centred in their rows, with the remove (−) button beside them.
- Switching between Build Archives and Folder Preview cross-fades and keeps each pane's scroll position.
- "Saved locally…" stays pinned to the bottom of Build Archives.
- The form keeps a 440 pt minimum width, so controls and the Build button no longer clip when the window shrinks.
- The form now runs Project Folder, Format, Footage Sources, then one Final Cut Pro section (Leave files in place + Smart Collections).
- Footage source presets are two columns of checkboxes.
- Smart Collections linked to a footage source say "from Footage Sources" in their summary, instead of a hover-only link icon.
- Minimum macOS is now 15 (was 14.6, which was never tested).
- The DMG app runs on both Apple silicon and Intel Macs.
- The DMG is signed with a Developer ID and notarized, so it installs without Gatekeeper warnings.
- The build number is the commit count, so each release is higher than the last.
- Copyright and app category (Video) are set, so they show in About and Finder's Get Info.
- The About window's GitHub link points to github.com/PixelEtch/Slateflow.
- The privacy note and README mention the update check, the app's only network request.
- The Folder Preview also lists `Slate Project.json`, so it shows every file a build writes.

### Fixed
- Project numbering continues past 999; before, every build after `999 - …` failed with "already exists".
- A build that fails partway removes the folder it started, so a retry reuses the same number.
- The Build Archives entry and `Slate Project.json` always describe the same configuration, even if the form is edited while a build runs.
- "Leave files in place" and other Final Cut settings could reset at launch: restoring one setting saved the others before they were read.
- A saved Portrait or Vertical aspect ratio, such as 9:21, came back as that orientation's default (9:16) at launch.
- Add Collection > Screen Recordings no longer adds a second copy of the built-in Screen Recordings collection; collections with the same rules are never added twice.

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
