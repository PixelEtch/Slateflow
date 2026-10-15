# ADR-0004: Repository conventions adopted from Vorssaint

**Date**: 2026-10-15
**Status**: accepted
**Deciders**: Sk Ashifali Shaikh

## Context

`vorssaint/vorssaint-utils` is a mature open-source macOS app with a clear repository layout. Slateflow already has a changelog, contributing and security guides, issue and PR templates, CI and a DMG script. This records which remaining pieces we take.

## Decision

We add `.github/dependabot.yml` (GitHub Actions, weekly; Dependabot cannot read Xcode project packages, so Sparkle is updated by hand), `.github/CODEOWNERS`, `SUPPORT.md`, `docs/PRIVACY.md`, `docs/TROUBLESHOOTING.md`, and README sections for Install, Uninstall and Build it yourself.

## Alternatives Considered

### Copy everything
- **Pros**: identical structure.
- **Cons**: `TRADEMARKS.md` (no registered brand), `FUNDING.yml` (no sponsorships yet), `PERMISSIONS.md` (the sandbox already limits access), `uninstall.sh` (dragging the app to the Trash is enough) would be empty ceremony.
- **Why not**: each file must earn its place; add these when the need appears.

## Consequences

### Positive
- Actions updates arrive as reviewed PRs.
- Users find privacy, support and troubleshooting answers without opening issues.

### Negative
- More documents to keep current.

### Risks
- Docs drift from the app. Mitigation: update them in the same commit as the behaviour they describe.
