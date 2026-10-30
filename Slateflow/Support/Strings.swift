//
//  Strings.swift
//  Slateflow
//
//  Every user-facing string in the UI. One place to edit copy.
//

import Foundation

enum Strings {

    enum App {
        static let inspector = "Inspector"
        static let inspectorToggleHelp = "Show or hide the inspector"
    }

    enum Format {
        static let section = "Format"
        static let resolution = "Resolution"
        static let orientation = "Orientation"
        static let dimensions = "Dimensions"
        static let width = "Width"
        static let height = "Height"
        static let frameRate = "Frame rate"
        static let outputSize = "Output size"
        static let aspectRatio = "Aspect ratio"
        static let dimensionSeparator = "×"
        static let dimensionsOdd = "Final Cut needs even dimensions - odd values round down on build."
        static let colorSpace = "Color space"
        static let colorSpaceHelp = "The color space you edit and export in. Footage from any camera is converted to it, and the library is set up to match."
        static let reelTimeline = "Reel timeline"
        static let reelTimelineHelp = "Also adds a 9:16 timeline for reels, next to the main one."
        static let dimensionsTooSmall = "Width and height must be at least \(VideoFormat.minimumSide) px."
    }

    enum ProjectFolder {
        static let section = "Project Folder"
        static let templateName = "Project name"
        static let rootFolder = "Root folder"
        static let sequenceNote =
            "The 3-digit prefix is assigned on build, from the numbered folders already "
            + "in the location you pick."
    }

    enum FootageSources {
        static let section = "Footage Sources"
        static let addLabel = "Other source"
        static let addPrompt = "Other source, e.g. Lumix S5"
        static let add = "Add source"
        static func remove(_ name: String) -> String { "Remove \(name)" }
    }

    enum Folders {
        static let section = "Folders"
        static let addLabel = "New folder"
        static let addPrompt = "New folder, e.g. Admin/Contracts"
        static let add = "Add folder"
        static func remove(_ path: String) -> String { "Remove \(path)" }
        static let reset = "Restore Defaults"
        static let none = "Only Backup, FCP and Footage"
        static let footer = "Use / for a subfolder. Backup, FCP and Footage are always created."
    }

    enum FCP {
        static let section = "Final Cut Pro"
        static let leaveFilesInPlace = "Leave files in place"
        static let leaveFilesInPlaceHelp =
            "Media stays in the project’s folders. Turn on the same setting in Final Cut Pro ▸ Settings ▸ Import."
    }

    enum SmartCollections {
        static let footer =
            "Enabled collections go into the project's .fcpxml and sort clips automatically on import."
        static let add = "Add Collection"
        static let screenRecordings = "Screen Recordings"
        static let byCameraAngle = "By Camera Angle…"
        static let byShootDay = "By Shoot Day…"
        static let byKeyword = "By Keyword…"
        static let videoRole = "Video Role…"
        static let audioRole = "Audio Role…"
        static let remove = "Remove"
        static func remove(_ name: String) -> String { "Remove \(name)" }
        static let fromFootageSources = "from Footage Sources"

        enum Draft {
            static let cancel = "Cancel"
            static let add = "Add"

            static let cameraAngleTitle = "New Camera Angle Collection"
            static let shootDayTitle = "New Shoot Day Collection"
            static let keywordTitle = "New Keyword Collection"
            static let videoRoleTitle = "New Video Role"
            static let audioRoleTitle = "New Audio Role"

            static let cameraAnglePrompt = "Cam A"
            static let shootDayPrompt = "Day 01"
            static let keywordPrompt = "B-Roll"
            static let rolePrompt = "Role name"

            static let cameraAngleHelp =
                "Matches clips whose Inspector ▸ Info ▸ Camera Angle equals this value."
            static let shootDayHelp =
                "Matches the keyword FCP creates when a day’s folder is imported with “Keywords: from folders”."
            static let keywordHelp = "Matches clips tagged with this keyword."
            static let roleHelp =
                "Creates the role and a Smart Collection that gathers every clip assigned to it."
        }
    }

    enum Inspector {
        static let viewPicker = "View"
        static let archives = "Build Archives"
        static let preview = "Folder Preview"
        static let clearHistory = "Clear Archive"
        static func clearConfirmTitle(count: Int) -> String {
            "Delete all \(count) build record\(count == 1 ? "" : "s")?"
        }
        static let clearConfirmAction = "Delete All"
        static let clearConfirmMessage = "This can't be undone. The projects on disk aren't affected - only this history list."
        static let backupMenu = "Backup"
        static let exportBackup = "Export Backup…"
        static let importBackup = "Import Backup…"
        static let backupErrorTitle = "Backup failed"
    }

    enum History {
        static let emptyTitle = "No Builds Yet"
        static let emptyMessage =
            "Configure the options on the left, then build a project. "
            + "Each successful build records a locked-in snapshot here."
        static let orientation = "Orientation"
        static let size = "Size"
        static let roles = "Roles"
        static let collections = "Collections"
        static let footageSources = "Footage sources"
        static let leaveFilesInPlace = "Leave files in place"
        static let copyIntoLibrary = "Copy into library"
        static let reuse = "Use These Settings"
        static let reuseHelp =
            "Restores resolution, aspect, frame rate, and leave-in-place from this build. "
            + "Roles, Smart Collections, and footage sources aren't restored - only their counts were saved."
        static let delete = "Delete"
        static let storageNote = "Saved locally in Application Support. Never leaves this Mac."
    }

    enum Preview {
        static let footer = "Created inside the folder you choose when you build."
        static func note(_ text: String) -> String { "· \(text)" }
    }

    enum Help {
        static let guide = "Slateflow Help"
        static let troubleshooting = "Troubleshooting"
        static let releaseNotes = "Release Notes"
        static let privacy = "Privacy"
        static let reportIssue = "Report an Issue…"
    }

    enum About {
        static let menuItem = "About Slateflow"
        static let openLog = "Open Log File"
        static let checkForUpdates = "Check for Updates…"
        static let privacy =
            "100% local. Slateflow runs entirely on your Mac - no telemetry, no cloud, "
            + "no tracking. Your files and configurations never leave this machine. "
            + "The only network request is the update check."
        static let github = "View on GitHub"
        static let license = "Released under the MIT License."
        static let viewLicense = "View License"
        static let licenseTitle = "MIT License"
        static let done = "Done"

        static let mitLicense = """
        MIT License

        Copyright (c) 2026 Sk Ashifali Shaikh

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        """
    }

    enum Build {
        static let menuItem = "Build Project…"
        static let button = "Choose Destination & Build…"
        static let buildHere = "Build"
        static func destination(_ folder: String) -> String { "in \(folder)" }
        static let change = "Change…"
        static let changeHelp = "Choose another folder for new projects"
        static let panelPrompt = "Build Here"
        static func panelMessage(rootFolder: String) -> String {
            "Choose where to create “\(rootFolder)”."
        }
        static let errorTitle = "Couldn’t build the project"
        static let ok = "OK"
        static let chooseAnother = "Choose Another Folder…"
        static let successTitle = "Project created"
        static let nextStepsTitle = "In Final Cut Pro"
        static let openInFCP = "Open in Final Cut Pro"
        static let creatingLibrary = "Creating library…"
        static let libraryNote = "Final Cut opens the project and creates its library in the project's FCP folder."
        static let importHint = "Before importing media, turn on Leave files in place in Final Cut Pro ▸ Settings ▸ Import."
        static let backupsHint = "When Final Cut asks for storage locations, set Backups to this project's Backup folder. Media and render files already stay inside the project."
        static let libraryFailed = "Final Cut didn't create the library. Check that Final Cut Pro is installed, then click Open in Final Cut Pro again."
        static let reveal = "Reveal in Finder"
        static let done = "Done"
    }
}
