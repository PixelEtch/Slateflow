# ADR-0002: Sign and notarize releases locally, not in CI

**Date**: 2026-10-15
**Status**: accepted
**Deciders**: Sk Ashifali Shaikh

## Context

A release needs three secrets: the Developer ID certificate, notarization credentials, and Sparkle's EdDSA private key. Vorssaint signs in GitHub Actions on a `v*` tag, with the secrets in a protected `release-signing` environment. Slateflow has one maintainer and releases rarely.

## Decision

Releases are built on the maintainer's Mac with `Tools/make-dmg.sh`, using the keychain certificate, the `slateflow-notary` notarytool profile and the keychain EdDSA key. CI only builds and runs the self-check; it holds no signing secrets.

## Alternatives Considered

### Tag-triggered release workflow (Vorssaint's `release.yml`)
- **Pros**: repeatable, release from any machine, release notes from the changelog.
- **Cons**: the `.p12`, an App Store Connect API key and the Sparkle key live in GitHub secrets.
- **Why not**: a leak of those secrets lets anyone ship malware as Slateflow; not worth it at the current release rate.

## Consequences

### Positive
- Signing keys never leave the maintainer's Mac.
- No secrets to rotate on GitHub.

### Negative
- Publishing is manual: create release `v<version>`, attach the DMG, push `docs/appcast.xml`.
- Releases need the maintainer's Mac.

### Risks
- Steps get skipped by hand. Mitigation: the script prints the remaining steps; docs/RELEASING.md lists them. Revisit with a protected-environment workflow once releases are frequent.
