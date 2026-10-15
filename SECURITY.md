# Security Policy

## Supported versions

Only the latest release receives security fixes.

## Reporting a vulnerability

Please don't open a public issue for security problems.

Report them privately through GitHub: on the repository page, go to **Security → Report a vulnerability**. Include what you found, the steps to reproduce it, and the macOS and Slateflow versions.

You'll get a reply within 7 days. Once a fix is released, the report can be made public, with credit to you if you'd like.

## Scope

Slateflow runs locally. Its only network access is the Sparkle update check, which accepts an update only if its EdDSA signature matches the key built into the app. The areas that matter most are:

- writing files only inside the folder the user picks (path traversal, symlinks)
- the files it generates (`.fcpxml`, `Slate Project.json`) and how other apps read them
- local data in the app's container (build history, log)
- the update path: the feed at `pixeletch.github.io/Slateflow/appcast.xml` and DMGs on GitHub Releases
