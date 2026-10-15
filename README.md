# Slateflow

A small macOS app that sets up a new Final Cut Pro project folder in one click, so every edit starts with the same structure.

## What it does

- Creates a numbered project folder (`001 - Name`, `002 - Name`, …), picking the next free number in the folder you choose.
- Builds the same folder tree every time: Admin, Audio, Backup, FCP, Final Exports, Footage, Graphics and Images.
- Adds a `Footage` subfolder for each camera source you turn on (Cam A/B, Drone, GoPro, Insta360, DJI Osmo, Sony, iPhone, Webcam, Screen Recordings, Stock Footage) or name yourself.
- Writes an `.fcpxml` with your resolution, aspect ratio and frame rate, custom roles, and Smart Collections that sort clips on import.
- Saves `Slate Project.json` in each project, describing how it was built.
- Keeps **Build Archives**, a list of past builds whose settings you can reuse.

The **Folder Preview** shows exactly what a build will create.

## Install

Download `Slateflow-<version>.dmg` from [Releases](https://github.com/PixelEtch/Slateflow/releases/latest), open it and drag **Slateflow** onto **Applications**. It's signed and notarized by Apple, so it opens normally.

Updates arrive through **Slateflow > Check for Updates…**.

Requires macOS 15 or later, and Final Cut Pro to open the projects.

## Use it

1. Pick the format, footage sources, roles and Smart Collections.
2. Click **Choose Destination & Build…** and choose where the project goes.
3. Click **Copy Name & Open in Final Cut Pro**. When Final Cut asks for a library, click **New…**, paste the name (⌘V) and click **Save**. The save window already opens in the project's `FCP` folder.

Final Cut creates the library itself, so it always matches your installed version.

## Uninstall

Move Slateflow from Applications to the Trash. To also remove its settings, Build Archives and log, delete `~/Library/Containers/com.ashifali.Slateflow`. Projects you built are not touched.

## Privacy

Everything stays on your Mac: no accounts, telemetry or cloud. The only network request is the update check. See [docs/PRIVACY.md](docs/PRIVACY.md).

## More

- [Troubleshooting](docs/TROUBLESHOOTING.md) · [Getting help](SUPPORT.md)
- [Contributing](CONTRIBUTING.md): building from source (Xcode 26), the self-check, and pull requests
- [Code of Conduct](CODE_OF_CONDUCT.md) · [Security](SECURITY.md)
- [Releasing](docs/RELEASING.md) · [Architecture decisions](docs/adr/README.md) · [Domain terms](CONTEXT.md)
- [Changelog](CHANGELOG.md)

## License

MIT. See [LICENSE](LICENSE).
