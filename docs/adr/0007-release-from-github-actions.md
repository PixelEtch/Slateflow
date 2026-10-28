# ADR-0007: Sign, notarize and publish releases from GitHub Actions

**Date**: 2026-10-28
**Status**: accepted
**Deciders**: Sk Ashifali Shaikh

## Context

ADR-0002 kept signing on the maintainer's Mac, so every release meant running `Tools/make-dmg.sh`, creating the GitHub release by hand and pushing the appcast afterwards, in the right order. Vorssaint releases from a `v*` tag with its signing secrets in a protected environment. The maintainer wants the same: push a tag and get a published, notarized release with an updated Sparkle feed.

## Decision

`.github/workflows/release.yml` runs on a `vX.Y.Z` tag in three jobs. **Preflight** has no secrets: the tag is on `main`, matches `MARKETING_VERSION` and a dated `CHANGELOG.md` heading, and the Debug build passes the self-check. **Sign & notarize** runs in the `release-signing` environment: it imports the Developer ID certificate into a throwaway keychain, runs `Tools/make-dmg.sh` with an App Store Connect API key and the Sparkle EdDSA key, and deletes them afterwards. **Publish** has only `contents: write`: it checks the files and the tag, creates the GitHub release, then pushes `appcast.xml` to the `gh-pages` branch that GitHub Pages serves. The feed moves off `main`, so the bot never needs to bypass `main`'s protection. `make-dmg.sh` still works on the Mac with the keychain, as a fallback.

## Alternatives Considered

### Keep signing on the maintainer's Mac (ADR-0002)
- **Pros**: signing keys never leave the Mac.
- **Cons**: manual, order-sensitive publishing; releases need that Mac.
- **Why not**: the maintainer chose repeatable tag releases; a protected environment limits the exposure.

### Commit the appcast to `main` from CI
- **Why not**: `main` requires pull requests, so the bot would need a ruleset bypass.

## Consequences

### Positive
- A release is: bump the version, date the changelog, push a tag.
- The GitHub release always exists before the feed points at it.

### Negative
- Six secrets live in GitHub: the `.p12` and its password, an App Store Connect API key (key, key ID, issuer ID) and the Sparkle private key.
- GitHub Pages serves the `gh-pages` branch, not `main`'s `docs/`.

### Risks
- A leak of those secrets lets someone sign malware as Slateflow. Mitigation: they exist only in `release-signing`, which requires the maintainer's approval and only accepts `v*` tags; the job that can write to the repository never sees them. Rotate the certificate, API key and Sparkle key if a run or the environment is ever compromised.
