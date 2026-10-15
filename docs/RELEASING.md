# Releasing

For the maintainer. Releases are signed and notarized on the maintainer's Mac, never in CI ([ADR-0002](adr/0002-local-release-signing.md)).

## One-time setup

These live in the login keychain of the release Mac:

- **Developer ID Application** certificate (team `GG4G6A42SB`).
- notarytool profile **`slateflow-notary`**, created with `xcrun notarytool store-credentials`.
- Sparkle EdDSA private key, account **`slateflow`**. Keep an offline backup; without it, installed copies can never update again.

GitHub Pages must serve `docs/` from `main` (Settings → Pages), which needs the repository to be public.

## Each release

1. Bump **`MARKETING_VERSION`** in Xcode (for example `1.1.0`). The build number is the commit count, set by the script.
2. Move the **Unreleased** entries in `CHANGELOG.md` under a heading for the new version, and commit.
3. Run:

   ```bash
   ./Tools/make-dmg.sh
   ```

   It builds a universal Release app, signs it and Sparkle's helpers with the Developer ID, packages `dist/Slateflow-<version>.dmg`, notarizes and staples it, and adds it to `docs/appcast.xml` with an EdDSA signature. It uploads and pushes nothing.

4. On GitHub, create release **`v<version>`** from `main` and attach `dist/Slateflow-<version>.dmg`. The tag must match: the appcast points at `releases/download/v<version>/Slateflow-<version>.dmg`.
5. Commit and push `docs/appcast.xml`.
6. Check `https://pixeletch.github.io/Slateflow/appcast.xml` shows the new version, then use **Slateflow > Check for Updates…** in an older copy.

Push the appcast only after the release exists; otherwise apps find an update they can't download.
