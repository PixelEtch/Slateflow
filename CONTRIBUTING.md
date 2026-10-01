# Contributing to Slateflow

Thanks for helping. Slateflow is a small macOS app, so the process is light.

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

CI runs the same build and check on every pull request.

When you change logic in `Slateflow/Model`, add an `assert` for it in `SlateSelfCheck.swift`.

## Code style

- Match the surrounding code: naming, comment density, and SwiftUI idioms.
- Put user-facing text in `Support/Strings.swift`, and spacing, colours and SF Symbol names in `Support/DesignSystem.swift`. Views reference those instead of literals.
- Keep changes focused: one fix or feature per pull request.
- Add a line to `CHANGELOG.md` under **Unreleased** for anything a user would notice.

## Pull requests

- Branch from `main`.
- Describe what changed and why, and how you tested it. Add a screenshot for UI changes.
- Make sure CI passes.

## License

By contributing, you agree that your contributions are licensed under the MIT License in [LICENSE](LICENSE).
