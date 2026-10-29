# Privacy

Slateflow runs on your Mac. It has no accounts, analytics, telemetry or tracking, and it collects no data.

## What it stores, and where

The app is sandboxed, so everything it keeps lives in its own container:

| What | Where |
|---|---|
| Settings (format, project name, footage sources, roles, Smart Collections, inspector state) | `~/Library/Containers/com.ashifali.Slateflow/Data/Library/Preferences/com.ashifali.Slateflow.plist` |
| Build history | `~/Library/Containers/com.ashifali.Slateflow/Data/Library/Application Support/Slateflow/BuildHistory.json` |
| Log | `~/Library/Containers/com.ashifali.Slateflow/Data/Library/Application Support/Slateflow/Slate.log` (**Help > Open Log File**) |

The project folders, `.fcpxml` and `Slate Project.json` it creates are written only inside the folder you pick.

## Network

The only network request is the update check. Sparkle downloads `https://pixeletch.github.io/Slateflow/appcast.xml` from GitHub Pages and, when you accept an update, the DMG from GitHub Releases. The request carries the app name and version in its user agent and nothing about you, your Mac or your files. GitHub's own [privacy statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement) applies to those servers. The Help menu's links (Slateflow Help, Troubleshooting, Release Notes, Privacy, Report an Issue) open GitHub pages in your browser; the app itself sends nothing.

On the second launch Sparkle asks whether to check automatically. To turn automatic checks off later:

```bash
defaults write ~/Library/Containers/com.ashifali.Slateflow/Data/Library/Preferences/com.ashifali.Slateflow SUEnableAutomaticChecks -bool NO
```

## Removing everything

Quit Slateflow, move it from Applications to the Trash, then delete `~/Library/Containers/com.ashifali.Slateflow`.
