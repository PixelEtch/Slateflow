# ADR-0001: Direct-download DMG with Sparkle; App Sandbox stays on

**Date**: 2026-10-15
**Status**: accepted
**Deciders**: Sk Ashifali Shaikh

## Context

Slateflow is free and open source. It should reach users without App Review, install without Gatekeeper warnings, and update itself from inside the app. The app is sandboxed, so it cannot replace its own bundle in `/Applications`.

## Decision

We ship a Developer ID-signed, notarized DMG on GitHub Releases. Sparkle 2 (SPM) checks `https://pixeletch.github.io/Slateflow/appcast.xml`, verifies each update with an EdDSA signature, and installs it through its sandboxed installer launcher service. The App Sandbox stays on.

## Alternatives Considered

### Mac App Store
- **Pros**: silent automatic updates, no updater code.
- **Cons**: App Review on every release, store rules on features.
- **Why not**: the goal is free distribution without review.

### Home-made updater (as in vorssaint/vorssaint-utils)
- **Pros**: no dependency, feed is the GitHub Releases API.
- **Cons**: needs the sandbox off (it mounts DMGs, runs `codesign`/`ditto`, asks for admin rights); we would own every signature check.
- **Why not**: Sparkle already does this safely and works inside the sandbox.

### Notify only (link to the release page)
- **Pros**: about 40 lines, no dependency.
- **Cons**: users download and replace the app by hand.
- **Why not**: most users would stay on old versions.

## Consequences

### Positive
- One-click, signature-verified updates.
- The sandbox limits the app to files the user picks, plus the update check.

### Negative
- One third-party dependency (Sparkle), pinned in `Package.resolved`.
- Each release must update the appcast. (Since [ADR-0007](0007-release-from-github-actions.md) the release workflow publishes it to `gh-pages`.)

### Risks
- Losing the EdDSA private key (login keychain, Sparkle account `slateflow`) means installed copies can never update again. Mitigation: keep an encrypted backup (`generate_keys --account slateflow -x <file>`).
