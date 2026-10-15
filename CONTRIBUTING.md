# Contributing to Slateflow

Thanks for helping. Slateflow is a small macOS app, so the process is light. Everyone taking part follows the [Code of Conduct](CODE_OF_CONDUCT.md).

Before changing how the app is built or shipped, read [CONTEXT.md](CONTEXT.md) for the terms the code uses and the [architecture decisions](docs/adr/README.md) for what's already settled.

## Before you start

- For a bug, open an issue with the steps to reproduce it.
- For a feature or a bigger change, open an issue first so we can agree on the approach before you write code.

## Building

1. Open `Slateflow.xcodeproj` in Xcode 26 or later.
2. Run the **Slateflow** scheme.

Xcode signs the app for your own Mac automatically, so no Apple Developer account is needed to build and run.

## Checks

Debug builds run a self-check of the core logic at launch. Run it on its own before opening a pull request:

```bash
xcodebuild -project Slateflow.xcodeproj -scheme Slateflow -configuration Debug -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
build/Build/Products/Debug/Slateflow.app/Contents/MacOS/Slateflow --selftest
```

CI runs the same build and check on every pull request, plus an unsigned Release build for both Apple silicon and Intel:

```bash
xcodebuild -project Slateflow.xcodeproj -scheme Slateflow -configuration Release -destination 'generic/platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

When you change logic in `Slateflow/Model`, add an `assert` for it in `SlateSelfCheck.swift`.

## Code style

- Match the surrounding code: naming, comment density, and SwiftUI idioms.
- Put user-facing text in `Support/Strings.swift`, and spacing, colours and SF Symbol names in `Support/DesignSystem.swift`. Views reference those instead of literals.
- Keep changes focused: one fix or feature per pull request.
- Add a line to `CHANGELOG.md` under **Unreleased** for anything a user would notice.

## Pull requests

- Fork the repository and branch from `main`.
- Describe what changed and why, and how you tested it. Add a screenshot for UI changes.
- CI runs once a maintainer approves it for first-time contributors.

A pull request is merged when:

- the **Build & self-check** CI job passes (Debug build, `--selftest`, Release build),
- the branch is up to date with `main`,
- a code owner has approved it and every review conversation is resolved,
- `CHANGELOG.md` has a line under **Unreleased** for anything a user would notice.

Pull requests are squash-merged, so `main` gets one commit per change.

These need an issue and agreement first, because they go against how Slateflow works today:

- new network access beyond the update check, or any telemetry (see [docs/PRIVACY.md](docs/PRIVACY.md)),
- turning off the App Sandbox or changing how updates are delivered ([ADR-0001](docs/adr/0001-dmg-with-sparkle-sandboxed.md)),
- new third-party dependencies.

Never include signing certificates, keys, tokens or other credentials in a pull request.

## License

By contributing, you agree that your contributions are licensed under the MIT License in [LICENSE](LICENSE).
