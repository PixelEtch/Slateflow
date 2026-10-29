# Releasing

For the maintainer. Pushing a tag `vX.Y.Z` runs `.github/workflows/release.yml`, which signs, notarizes and publishes the release ([ADR-0007](adr/0007-release-from-github-actions.md)).

## One-time setup

1. **GitHub Pages**: Settings → Pages → Deploy from a branch → `gh-pages`, folder `/ (root)`. The first release creates the branch; Pages needs the repository to be public. The feed is `https://pixeletch.github.io/Slateflow/appcast.xml`.
2. **Environment**: Settings → Environments → New environment `release-signing`. Add yourself under **Required reviewers**, and under **Deployment branches and tags** allow only tags matching `v*`.
3. **Secrets** in that environment (not repository secrets):

   | Secret | What to put in it |
   |---|---|
   | `SIGNING_CERT_P12` | Keychain Access → **Developer ID Application: Sk Ashifali Shaikh (GG4G6A42SB)** → Export as `.p12`, then `base64 -i cert.p12 \| pbcopy` |
   | `SIGNING_CERT_PASSWORD` | The password you gave the `.p12` |
   | `NOTARY_API_KEY_P8` | App Store Connect → Users and Access → Integrations → Team Keys → new key with **Developer** access; paste the whole `.p8` file |
   | `NOTARY_KEY_ID` | That key's Key ID |
   | `NOTARY_ISSUER_ID` | The Issuer ID shown above the keys |
   | `SPARKLE_ED_PRIVATE_KEY` | `build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account slateflow -x key.txt`, then the contents of `key.txt` |

   Delete `cert.p12` and `key.txt` afterwards. Keep an offline backup of the Sparkle key: without it, installed copies can never update again.

## Each release

1. Bump **`MARKETING_VERSION`** in Xcode (for example `1.1.0`, or `1.1.0-beta.1` for a pre-release). The build number is the commit count, set by the script, so Sparkle always sees each release as newer than the last.
2. Move the **Unreleased** entries in `CHANGELOG.md` under `## 1.1.0 - YYYY-MM-DD`. Merge both to `main`.
3. Tag the merge commit and push the tag:

   ```bash
   git tag v1.1.0 && git push origin v1.1.0
   ```

4. Approve the **Sign & notarize** job when GitHub asks (Actions → the run → Review deployments).
   If GitHub cancels a job because no macOS runner was free, the **Re-run jobs GitHub never started** workflow re-runs it after 10 minutes (up to twice); approve signing again when asked.
5. When the run is green, check that `https://pixeletch.github.io/Slateflow/appcast.xml` lists the new version, then use **Slateflow > Check for Updates…** in an older copy.

The workflow stops before signing if the tag isn't on `main`, doesn't match `MARKETING_VERSION`, has no dated changelog heading, or **Build & self-check** hasn't passed for that commit (push to `main` and let CI finish before tagging). The release notes are that changelog section. Tags with `-alpha.N`, `-beta.N` or `-rc.N` are published as GitHub pre-releases.

Pre-releases go into the same Sparkle feed as final releases, so anyone on a pre-release is offered the next one, through to the final. After 1.0.0, put pre-releases on a separate Sparkle channel (`generate_appcast --channel beta`) before shipping one, or every 1.x user would be offered it.

## Releasing from the Mac instead

`./Tools/make-dmg.sh` still works with the keychain: the Developer ID certificate, the notarytool profile `slateflow-notary` and the Sparkle key (account `slateflow`). Start from the live feed so older items stay: `curl -o docs/appcast.xml https://pixeletch.github.io/Slateflow/appcast.xml`. Then create the GitHub release `v<version>` with the DMG first, and only then commit `docs/appcast.xml` as `appcast.xml` on `gh-pages`.
