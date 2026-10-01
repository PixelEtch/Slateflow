# Slateflow

A small macOS app that sets up a new Final Cut Pro project folder in one click, so every edit starts with the same structure.

## What it does

- Creates a numbered project folder (`001 - Name`, `002 - Name`, …). The number is picked from the folders already in the location you choose.
- Builds the full folder tree: Admin, Audio, Footage, Graphics, Images, Final Exports, Backup and FCP.
- Adds one `Footage` subfolder per camera source you turn on: Cam A/B, Drone, GoPro, Insta360, DJI Osmo, Sony, iPhone, Webcam, Screen Recordings, Stock Footage, or any name you type.
- Writes an `.fcpxml` with the resolution, aspect ratio and frame rate you picked, plus Smart Collections for each footage source, media type and role.
- Keeps a local archive of past builds, so a previous setup can be reused.

## Installing

Open `Slateflow-<version>.dmg` and drag **Slateflow** onto **Applications**.

The app is signed ad hoc, not with an Apple Developer ID, so Gatekeeper rejects it: dragging it to Applications fails with "Could not install - This Mac could not verify the app". Until it is signed and notarized, install it from Terminal instead:

```bash
ditto "/Volumes/Slateflow/Slateflow.app" "/Applications/Slateflow.app"
```

To make the DMG yourself:

```bash
./Tools/make-dmg.sh
```

It builds a Release app and writes `dist/Slateflow-<version>.dmg`.

## Opening the project in Final Cut Pro

After a build, click **Copy Name & Open in Final Cut Pro**. When Final Cut asks which library to import into, click **New…**, paste the name (⌘V), then click **Save**. The save window already opens in the project's `FCP` folder.

Final Cut creates the library itself, so it always matches your installed version and never asks to update.

## Requirements

- macOS 15 or later
- Final Cut Pro, to open the generated project
- Xcode 26 or later, to build from source

## Building

Open `Slateflow.xcodeproj` in Xcode and run the **Slateflow** scheme, or from Terminal:

```bash
xcodebuild -project Slateflow.xcodeproj -scheme Slateflow -configuration Debug build
```

## Self-check

Debug builds run a set of checks on the core logic every time they start: folder naming, the folder tree, the FCPXML output, and path safety. To run the checks without opening a window:

```bash
path/to/Slateflow.app/Contents/MacOS/Slateflow --selftest
```

It prints `Slateflow self-check passed` and exits 0; a failed check stops it with a non-zero exit. CI runs this on every push to `main` and on every pull request (`.github/workflows/ci.yml`).

## Privacy

Everything stays on your Mac. Build history is saved in Application Support, and the app has no network access, telemetry or cloud features.

## License

MIT. See [LICENSE](LICENSE).
