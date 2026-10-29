# ADR-0003: Public repository under the MIT License

**Date**: 2026-10-15
**Status**: accepted
**Deciders**: Sk Ashifali Shaikh

## Context

The Sparkle feed and DMG downloads must be reachable by anyone. GitHub Pages and release assets on a private repository need a paid plan. The code is already MIT-licensed, and the git history was checked for secrets (none found) and rewritten to a noreply author email.

## Decision

`PixelEtch/Slateflow` is public under the MIT License. GitHub Pages serves `docs/` from `main`. (Since [ADR-0007](0007-release-from-github-actions.md), Pages serves the `gh-pages` branch, which holds only the appcast.)

## Alternatives Considered

### Private repository
- **Pros**: source stays hidden.
- **Cons**: Pages, the appcast and downloads need a paid plan or separate hosting.
- **Why not**: Slateflow is meant to be open source.

### GPL-3.0 (Vorssaint's license)
- **Pros**: forks must stay open source.
- **Cons**: stricter terms; harder to reuse parts in other apps.
- **Why not**: MIT is simpler and already in place.

## Consequences

### Positive
- Free Pages, Releases and Actions minutes for public repos.
- Users can read and build the code they install.

### Negative
- Anyone can fork and rebrand the code.

### Risks
- A committed secret is public at once. Mitigation: keys stay in the keychain (ADR-0002); never commit `.p12`, `.p8` or key exports.
