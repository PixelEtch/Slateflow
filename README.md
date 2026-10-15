# Slateflow

A small macOS app that sets up a new Final Cut Pro project folder in one click, so every edit starts with the same structure.

## What it does

- Creates a numbered project folder (`001 - Name`, `002 - Name`, …). The number is picked from the folders already in the location you choose.
- Builds the full folder tree: Admin, Audio, Footage, Graphics, Images, Final Exports, Backup and FCP.
- Adds one `Footage` subfolder per camera source you turn on: Cam A/B, Drone, GoPro, Insta360, DJI Osmo, Sony, iPhone, Webcam, Screen Recordings, Stock Footage, or any name you type.
- Writes an `.fcpxml` with the resolution, aspect ratio and frame rate you picked, plus Smart Collections for each footage source, media type and role.
- Keeps a local archive of past builds, so a previous setup can be reused.

## Install

Download `Slateflow-<version>.dmg` from [Releases](https://github.com/PixelEtch/Slateflow/releases/latest), open it and drag **Slateflow** onto **Applications**.

The app is signed with a Developer ID and notarized by Apple. Later versions arrive through **Slateflow > Check for Updates…**.

## Uninstall

Quit Slateflow and move it from Applications to the Trash. To also remove its settings, build history and log, delete `~/Library/Containers/com.ashifali.Slateflow`. Projects you built are not touched.

## Releasing

```bash
./Tools/make-dmg.sh
```

One command, run on the maintainer's Mac:

1. Builds a universal Release app signed with the Developer ID certificate, hardened runtime on.
2. Packages `dist/Slateflow-<MARKETING_VERSION>.dmg`, signs it, notarizes it (`notarytool`, keychain profile `slateflow-notary`) and staples the ticket.
3. Adds the DMG to the Sparkle feed `docs/appcast.xml`, signed with the EdDSA key in the login keychain (account `slateflow`). Its download URL is `https://github.com/PixelEtch/Slateflow/releases/download/v<version>/Slateflow-<version>.dmg`.

The script creates no release and pushes nothing. To publish:

1. Bump `MARKETING_VERSION` in Xcode before running the script (the build number is the commit count).
2. Create GitHub release `v<version>` and attach the DMG.
3. Commit and push `docs/appcast.xml` to `main`.

GitHub Pages serves the feed from the `docs/` folder on `main` (Settings > Pages > Deploy from a branch > `main` / `/docs`) at `https://pixeletch.github.io/Slateflow/appcast.xml`, the `SUFeedURL` the app checks. Pages on a private repository needs a paid GitHub plan, so the repository must be public, or the feed hosted elsewhere and `SUFeedURL` changed.

## Opening the project in Final Cut Pro

After a build, click **Copy Name & Open in Final Cut Pro**. When Final Cut asks which library to import into, click **New…**, paste the name (⌘V), then click **Save**. The save window already opens in the project's `FCP` folder.

Final Cut creates the library itself, so it always matches your installed version and never asks to update.

## Requirements

- macOS 15 or later
- Final Cut Pro, to open the generated project
- Xcode 26 or later, to build from source

## Build it yourself

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

Everything stays on your Mac. Build history is saved in Application Support, and the app has no telemetry or cloud features. Its only network request is the update check (Sparkle), which you can turn off. Details in [docs/PRIVACY.md](docs/PRIVACY.md).

## Documentation

- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Privacy](docs/PRIVACY.md)
- [Getting help](SUPPORT.md) · [Contributing](CONTRIBUTING.md) · [Code of Conduct](CODE_OF_CONDUCT.md) · [Security](SECURITY.md)
- [Architecture decisions](docs/adr/README.md): why it ships as a DMG with Sparkle, signs locally, and is MIT-licensed

## License

MIT. See [LICENSE](LICENSE).
