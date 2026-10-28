# ADR-0006: Let Final Cut create the library from FCPXML's `library location` import option

**Date**: 2026-10-28
**Status**: accepted
**Deciders**: Sk Ashifali Shaikh

## Context

ADR-0005 created each project's library by clicking through Final Cut's library window with System Events. That needed Accessibility and Automation permissions and a temporary Apple Events sandbox exception, and it broke with a non-English Final Cut or any UI change. ADR-0005 said the `library location` import option was ignored, but Slateflow had only ever written `<library location="…">`, which is a different element. Apple documents that `<import-options>` with `library location` makes Final Cut create the library when none exists at that URL ([import-options](https://developer.apple.com/documentation/professional-video-applications/import-options)). On 2026-10-28, opening a test `.fcpxml` with that option in Final Cut Pro 12.4 created the library, its event and its project in about 10 seconds, with no dialog. This worked both with and without a trailing slash on the URL.

## Decision

Each project's `.fcpxml` starts with `<import-options>`, whose `library location` is `<root>/FCP/<root>.fcpbundle`, plus `suppress warnings`. Open in Final Cut Pro opens that file with `NSWorkspace` and waits for the library to appear. The System Events clicking, the permission prompts and the Apple Events entitlements are removed.

## Alternatives Considered

### Keep ADR-0005's clicking as a fallback
- **Pros**: one more way to recover.
- **Cons**: keeps two permissions, a sandbox exception and code that breaks with a non-English Final Cut.
- **Why not**: the import option does the same job with none of that.

### Write the `.fcpbundle` directly
- **Why not**: undocumented, version-specific format (unchanged from ADR-0005).

## Consequences

### Positive
- No permissions and no sandbox exception: Slateflow is back to plain App Sandbox (ADR-0001).
- Works with any Final Cut language; Final Cut still writes the library, so it matches the installed version.
- About 120 lines of AppleScript, permission UI and strings removed.

### Negative
- If Final Cut doesn't create the library, the only fallback is opening the project again.

### Risks
- Apple could change how Final Cut treats the import option. Mitigation: Slateflow waits up to 60 seconds for the library and logs it when it doesn't appear.
