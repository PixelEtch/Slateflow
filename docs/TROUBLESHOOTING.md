# Troubleshooting

Before anything else, open **Help > Open Log File**. Each build and error is logged there.

## "Update Error! An error occurred in retrieving update information."

Slateflow couldn't reach `pixeletch.github.io`. Check your internet connection, then try **Slateflow > Check for Updates…** again. A firewall or content blocker that blocks GitHub causes the same error.

## Slateflow can't write to the folder I picked

The app is sandboxed and can only write where you've given it access. Pick the location again in the form. If the folder is on an external drive, make sure the drive is connected and writable.

## Final Cut Pro doesn't open the project

Click **Open in Final Cut Pro** again. Final Cut Pro must be installed in `/Applications`.

## Final Cut doesn't create the library

- Wait for Final Cut to finish opening; the first launch can take a minute. Then click **Open in Final Cut Pro** again.
- Close any dialog that's open in Final Cut first.
- **Help > Open Log File** shows what Slateflow saw.

## Settings or build history look wrong

Quit Slateflow and delete `~/Library/Containers/com.ashifali.Slateflow`. This resets settings and clears build history; projects you already built are not touched.

## Still stuck

Open an issue (see [SUPPORT.md](../SUPPORT.md)) and attach the log.
