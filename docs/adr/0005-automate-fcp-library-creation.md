# ADR-0005: Create the Final Cut library by driving Final Cut's dialog

**Date**: 2026-10-19
**Status**: superseded by [ADR-0006](0006-fcp-library-via-import-options.md)
**Deciders**: Sk Ashifali Shaikh

## Context

After every build, users had to click New…, paste the name and click Save in Final Cut's library window. Slateflow can't write the `.fcpbundle` itself: the format is private and changes with each Final Cut version. FCPXML's `library-location` import option is ignored by Final Cut 12.4 when the file is opened (tested twice), and Final Cut's AppleScript can't create libraries.

## Decision

With the user's Accessibility permission, Slateflow sends Apple Events to System Events right after opening the `.fcpxml`: click New…, go to the project's `FCP` folder (⌘⇧G), paste the name, press Return, then check that the library exists. Without permission, or if any step fails, the success sheet shows the manual steps (New…, ⌘V, Return). App Sandbox stays on (ADR 0001), with a temporary Apple Events exception for `com.apple.systemevents`.

## Alternatives Considered

### Write the `.fcpbundle` directly
- **Why not**: undocumented, version-specific format; would break with Final Cut updates.

### FCPXML `library-location` import option
- **Why not**: Final Cut 12.4 ignores it when the file is opened.

### Copy a template library
- **Pros**: no permissions.
- **Cons**: users make an empty library first, again after major Final Cut updates.
- **Why not**: more setup than one permission switch.

### Accessibility API from the app
- **Why not**: App Sandbox blocks it (AXError -25204 even when trusted).

## Consequences

### Positive
- One click from build to an open, versioned library; Final Cut still creates it.
- Users who skip the permission keep a shorter manual flow.

### Negative
- Users grant Accessibility and Automation (System Events) once.
- The Mac App Store would likely reject the Apple Events exception (we ship a DMG, ADR 0001).

### Risks
- A Final Cut UI change or a non-English Final Cut breaks the clicks. Mitigation: the on-disk check falls back to the manual steps, and the log records which step failed.
