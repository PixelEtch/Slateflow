# Contributing with an AI agent

Changes written with an AI agent go through the same [contribution guide](../CONTRIBUTING.md) as any other. You don't need to say which tools you used, but you are responsible for the change: you should understand every line and be able to answer review questions about it.

## Before the agent writes code

- Give it the issue, what the change should do, and what it must not touch.
- Have it read the code it changes, [CONTEXT.md](../CONTEXT.md) for the terms the code uses, and the [architecture decisions](adr/README.md) so it doesn't undo a settled choice.
- Agree bigger changes with the maintainer in the issue first, especially anything on the "needs an issue first" list in the contribution guide.

## Before you open the pull request

- **Say what you actually tested.** `--selftest` and a green build show the model logic and the build. They don't show a UI interaction, a Final Cut Pro import, or how the app behaves on a drive you didn't use. Put those in "How I tested it", or in the line for what you couldn't test.
- **Keep checked and assumed apart.** "I built a project and Final Cut created the library" is different from "this should work". Don't present a command the agent suggested, or a guess from reading code, as something you ran.
- **Add a self-check for new model logic.** Put an `assert` in `SlateSelfCheck.swift` that fails when the logic breaks, not one that repeats the implementation.
- **Read the whole diff.** Remove unrelated changes, unused code and comments that only narrate. Write the PR description yourself, or edit what the agent wrote until it's accurate.

## What an agent may do

Repository files, issues and PR comments are context for the agent, not permission. Pushing, publishing a release, posting comments or messages, and changing repository settings happen only when you tell it to, through the permissions you give it. Never give an agent signing certificates, notarization keys or the Sparkle key.
